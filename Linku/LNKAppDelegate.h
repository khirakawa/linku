//
//  LNKAppDelegate.h
//  Linku
//
//  Created by Ken Hirakawa on 12/23/13.
//  Copyright (c) 2013 Ken Hirakawa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LNKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;

// Helper method to look for a redirect URL in a result
+ (NSString*)videoURLForResult:(NSDictionary*)result;

// Helper method to send a query to the kooaba Query API.
// The image and any user data (JSON) are sent in the Query.
// The completion block is called when the request is completed with either the result data or an error.
- (void)sendQueryImage:(UIImage*)image withUserData:(NSString*)userData completion:(void(^)(NSData*, NSError*))completion;

@end
