// NSURLSession, for iOS where there is no libcurl to load. Blocking like the other backends (the
// callers run it off the game's thread), with the same limits as http_curl.c: 30 seconds for a
// request, and for a download 30 seconds to connect or of no data. Built with ARC.
#import <Foundation/Foundation.h>
#include "sync/http.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void http_add_header(HttpResponse *res, const char *line, size_t len);

bool http_available(void) { return true; }

static bool run(NSMutableURLRequest *req, bool download, HttpResponse *res) {
  NSURLSessionConfiguration *cfg = NSURLSessionConfiguration.ephemeralSessionConfiguration;
  cfg.timeoutIntervalForRequest = 30;                       // the no-data limit between packets
  cfg.timeoutIntervalForResource = download ? 60 * 60 : 30; // whole request
  cfg.HTTPAdditionalHeaders = @{@"User-Agent" : @"Oracles"};
  NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];

  __block NSData *data = nil;
  __block NSHTTPURLResponse *http = nil;
  __block NSError *error = nil;
  dispatch_semaphore_t done = dispatch_semaphore_create(0);
  // redirects are followed by default, as with CURLOPT_FOLLOWLOCATION
  NSURLSessionDataTask *task = [session dataTaskWithRequest:req
                                          completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
                                            data = d;
                                            if ([r isKindOfClass:NSHTTPURLResponse.class]) http = (NSHTTPURLResponse *)r;
                                            error = e;
                                            dispatch_semaphore_signal(done);
                                          }];
  [task resume];
  dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
  [session finishTasksAndInvalidate];

  if (error && !http) {
    snprintf(res->error, sizeof res->error, "%s", error.localizedDescription.UTF8String ?: "request failed");
    return false;
  }
  res->status = (int)http.statusCode;
  [http.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    NSString *line = [NSString stringWithFormat:@"%@: %@", key, value];
    const char *s = line.UTF8String;
    if (s) http_add_header(res, s, strlen(s));
  }];
  size_t n = data.length;
  res->body = malloc(n + 1);
  if (!res->body) { snprintf(res->error, sizeof res->error, "out of memory"); return false; }
  if (n) memcpy(res->body, data.bytes, n);
  res->body[n] = 0;
  res->size = n;
  return res->status != 0;
}

bool http_request(const char *method, const char *url, const char *headers, const uint8_t *body, size_t size, HttpResponse *res) {
  memset(res, 0, sizeof *res);
  @autoreleasepool {
    NSURL *u = [NSURL URLWithString:@(url)];
    if (!u) { snprintf(res->error, sizeof res->error, "bad URL"); return false; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.HTTPMethod = @(method);
    req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    // "Name: value\n" lines
    for (const char *p = headers; p && *p;) {
      const char *eol = strchr(p, '\n');
      size_t len = eol ? (size_t)(eol - p) : strlen(p);
      const char *colon = memchr(p, ':', len);
      if (colon) {
        NSString *name = [[NSString alloc] initWithBytes:p length:(NSUInteger)(colon - p) encoding:NSUTF8StringEncoding];
        const char *v = colon + 1;
        while (v < p + len && (*v == ' ' || *v == '\t')) v++;
        size_t vlen = (size_t)(p + len - v);
        while (vlen && (v[vlen - 1] == '\r' || v[vlen - 1] == ' ')) vlen--;
        NSString *value = [[NSString alloc] initWithBytes:v length:vlen encoding:NSUTF8StringEncoding];
        if (name && value) [req setValue:value forHTTPHeaderField:name];
      }
      p += len + (eol ? 1 : 0);
    }
    if (body) req.HTTPBody = [NSData dataWithBytes:body length:size];
    return run(req, false, res);
  }
}

bool http_download(const char *url, HttpResponse *res) {
  memset(res, 0, sizeof *res);
  @autoreleasepool {
    NSURL *u = [NSURL URLWithString:@(url)];
    if (!u) { snprintf(res->error, sizeof res->error, "bad URL"); return false; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:u];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    return run(req, true, res);
  }
}
