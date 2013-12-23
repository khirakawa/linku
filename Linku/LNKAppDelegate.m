//
//  LNKAppDelegate.m
//  Linku
//
//  Created by Ken Hirakawa on 12/23/13.
//  Copyright (c) 2013 Ken Hirakawa. All rights reserved.
//

#import "LNKAppDelegate.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "LNKMasterViewController.h"
#import "LNKQueryRequest.h"

@interface LNKAppDelegate (/* Private */)

// We need an operation queue for the asynchronous network requests.
@property (strong, nonatomic) NSOperationQueue* networkOperationQueue;

@end

// The URL used to send the query to kooaba's Query API.
static NSString* kKooabaQueryURL = @"http://query-api.kooaba.com/v4/query";

// Add your Query Key ID
static NSString* kKooabaKeyID = @"0ba62968-9a6b-476a-8f2b-216f46a4c151";

// Add your Query Key Secret Token
static NSString* kKooabaSecretToken = @"Uk08uouPixXRmya8DZ20SCkTKxhdUJMyVwyID9pa";

// The maximum size for the query image. The longest dimension will be no longer than kMaximumImageSize.
// See http://docs.kooaba.com for more information on selecting the maximum image size.
static const double kMaximumImageSize = 640.0;

// The amount of compression to use when compressing the image, within the range of 0.0 (worst quality) - 1.0 (best quality).
// See http://docs.kooaba.com for more information on selecting an appropriate compression level.
static const double kJPEGCompressionLevel = 0.6;

@implementation LNKAppDelegate

@synthesize networkOperationQueue;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	// Override point for customization after application launch.
	
	LNKMasterViewController *masterViewController = [[LNKMasterViewController alloc] initWithNibName:@"LNKMasterViewController" bundle:nil];
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
	self.window.rootViewController = self.navigationController;
	[self.window makeKeyAndVisible];
    
	self.networkOperationQueue = [[NSOperationQueue alloc] init];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Send an image to the kooaba Query API and call the completion block when finished.
// The userData parameter must be a valid JSON string.
- (void)sendQueryImage:(UIImage*)image withUserData:(NSString*)userData completion:(void(^)(NSData*, NSError*))completion
{
	// Ideally, the UIImage would be converted to JPEG data on a background thread...
	NSData* data = UIImageJPEGRepresentation(image, 1.0);
	
	// Scale and send the image in the background so that we don't block the main thread any longer than we have to.
	dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(backgroundQueue, ^{
		
		// Scale the image so that the largest dimension is not larger than kMaximumImageSize.
		NSData* imageData = [self scaleImage:data maxSize:kMaximumImageSize];
		if (imageData != nil) {
            
			// Build the query request with the kooaba Query API URL and the scaled image data
			NSURL* queryURL = [NSURL URLWithString:kKooabaQueryURL];
			LNKQueryRequest* imageRequest = [[LNKQueryRequest alloc] initWithURL:queryURL imageData:imageData imageContentType:@"image/jpeg"];
			if (userData != nil) {
				// Encode the user_data parameter, if present, as a UTF-8 string
				imageRequest.userData = [userData dataUsingEncoding:NSUTF8StringEncoding];
			}
			
			// Sign the query request with your Query Key's access key and secret key
			NSMutableURLRequest* signedRequest = [imageRequest signedRequestWithKeyID:kKooabaKeyID secretToken:kKooabaSecretToken];
			
			// Tell the server we will accept a JSON response
			[signedRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
            
			// Turn on the network activity indicator on the main thread.
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
			});
            
			// Send the request asynchronously
			[NSURLConnection sendAsynchronousRequest:signedRequest queue:self.networkOperationQueue completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
				
				// Turn off the network activity indicator on the main thread and call the completion block with the result.
				dispatch_async(dispatch_get_main_queue(), ^{
					[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
					completion(data, error);
				});
			}];
		} else {
			// We encountered an unexpected error scaling the image.
			NSDictionary* errorInfo = [NSDictionary dictionaryWithObject:@"Could not scale image" forKey:NSLocalizedDescriptionKey];
			NSError* scalingError = [NSError errorWithDomain:@"QueryExampleErrorDomain" code:-1 userInfo:errorInfo];
			NSLog(@"%@", scalingError);
			
			// Turn off the network activity indicator on the main thread.
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
				completion(nil, scalingError);
			});
		}
	});
}

// Scale an image so that its largest dimension is not larger than maxSize.
// Assumes the image is a JPEG image.
- (NSData*)scaleImage:(NSData*)image maxSize:(CGFloat)maxSize
{
	NSData* imageData = nil;
	
	CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)image, NULL);
	if (imageSource != NULL) {
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways,
                                 [NSNumber numberWithFloat:maxSize], kCGImageSourceThumbnailMaxPixelSize,
                                 nil];
		CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
		if (thumbnail != NULL) {
			NSMutableData* data = [NSMutableData data];
			
			// Compress the image using JPEG compression and the specified compression level.
			CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, kUTTypeJPEG, 1, NULL);
			if (imageDestination != NULL) {
				NSDictionary* properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:kJPEGCompressionLevel] forKey:(id)kCGImageDestinationLossyCompressionQuality];
				CGImageDestinationAddImage(imageDestination, thumbnail, (__bridge CFDictionaryRef)properties);
				if (CGImageDestinationFinalize(imageDestination)) {
					imageData = data;
				}
				
				CFRelease(imageDestination);
			}
			
			CGImageRelease(thumbnail);
		}
		CFRelease(imageSource);
	}
	
	return imageData;
}

// Look for a URL to redirect to in the metadata attribute for an item
+ (NSString*)videoURLForResult:(NSDictionary*)result
{
	NSString* videoURL = nil;
	NSDictionary* metadata = [result objectForKey:@"metadata"];
	if ([metadata isKindOfClass:[NSDictionary class]]) {
		videoURL = [metadata objectForKey:@"video_url"];
	}
	
	return videoURL;
}

@end