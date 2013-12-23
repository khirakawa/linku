#import "LNKMasterViewController.h"
#import "LNKAppDelegate.h"


@interface LNKMasterViewController (/* Private */)

// The MasterViewController is the only one that needs access to these two views.
@property (nonatomic, strong, readwrite) IBOutlet UIImageView* imageView;
@property (nonatomic, strong, readwrite) IBOutlet MPMoviePlayerViewController* movieController;
@property (nonatomic, strong, readwrite) IBOutlet UIBarButtonItem* clickedButton;

@end

@implementation LNKMasterViewController

@synthesize imageView;
@synthesize movieController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.title = NSLocalizedString(@"Linku", nil);
	}
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Add a Camera button 
	UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(chooseImage:)];
	self.navigationItem.rightBarButtonItem = cameraButton;
    
	UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(chooseImage:)];
	self.navigationItem.leftBarButtonItem = uploadButton;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

// Show the camera if the device has one, otherwise show the photo library to choose a picture.
- (void)chooseImage: (id) sender
{
    self.clickedButton = sender;
    UIImagePickerController* pickerController = [[UIImagePickerController alloc] init];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
	}
	else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	}
	
	pickerController.delegate = self;
	[self presentModalViewController:pickerController animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];

	// Show the query image
	self.imageView.image = image;
	self.imageView.hidden = NO;

    if(self.clickedButton == self.navigationItem.rightBarButtonItem) {
        LNKAppDelegate* appDelegate = (LNKAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        // Send the image to the kooaba V4 Query service with some JSON user data.
        NSString* jsonUserData = @"{\"user_id\":\"ios_sample_code\"}";
        [appDelegate sendQueryImage:image withUserData:jsonUserData completion:^(NSData* data, NSError* error) {
            // This block is called when the query completes.
            // result will have the JSON response from the kooaba server or nil
            // error will have the error, if any
            
            // Hide the query image preview
            self.imageView.hidden = YES;
            
            NSDictionary* response = nil;
            if (data != nil && error == nil) {
                response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if ([response isKindOfClass:[NSDictionary class]] == NO) {
                    // We expect an object at the top level of the JSON response. If not, assume something went wrong.
                    response = nil;
                }
            }

            if (response != nil) {
                // We received a response. Display the result.
                NSLog(@"raw response:\n%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                // Check to see if the first item matched has a redirect_url attribute in its metatadata.
                NSString* videoURL = nil;
                NSArray* results = [response objectForKey:@"results"];
                if (results.count > 0) {
                    videoURL = [LNKAppDelegate videoURLForResult:[results objectAtIndex:0]];
                }
                
                if (videoURL != nil) {
                    NSURL *movieURL = [NSURL URLWithString:videoURL];
                    self.movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
                    [self presentMoviePlayerViewControllerAnimated:self.movieController];
                } else {
                    // Didn't find a match.  Show error message and camera.
                    NSLog(@"Did not find match");
                }
            } else {
            }
        }];
        
        [self dismissModalViewControllerAnimated:YES];
        
    } else {
        
    }

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
