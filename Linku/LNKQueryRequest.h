#import <Foundation/Foundation.h>


@interface LNKQueryRequest : NSObject

@property (nonatomic, strong, readwrite) NSData* userData;

// Create a query request with the Query API URL, compressed image data and the image content type.
// See http://docs.kooaba.com for more information on supported image types.
- (id)initWithURL:(NSURL*)requestURL imageData:(NSData*)data imageContentType:(NSString*)contentType;

// Create a signed query request with the specified key ID and secret token
- (NSMutableURLRequest*)signedRequestWithKeyID:(NSString*)keyID secretToken:(NSString*)secretToken;

@end
