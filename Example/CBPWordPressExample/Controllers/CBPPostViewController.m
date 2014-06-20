//
//  CBPPostViewController.m
//  CBPWordPressExample
//
//  Created by Karl Monaghan on 22/04/2014.
//  Copyright (c) 2014 Crayons and Brown Paper. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "NSString+CBPWordPressExample.h"

#import "JBWhatsAppActivity.h"
#import "GPPShareActivity.h"
#import "MHGallery.h"
#import "TOWebViewController.h"

#import "CBPCommentsViewController.h"
#import "CBPComposeCommentViewController.h"
#import "CBPPostListViewController.h"
#import "CBPPostViewController.h"

#import "CBPWordPressDataSource.h"

static const CGFloat CBPLoadPostViewHeight = 5.0;

@interface CBPPostViewController () <UIScrollViewDelegate, UIWebViewDelegate>
@property (nonatomic, assign) CGFloat baseFontSize;
@property (nonatomic, weak) CBPWordPressDataSource *dataSource;
@property (nonatomic) NSInteger index;
@property (nonatomic) UIBarButtonItem *nextPostButton;
@property (nonatomic) UILabel * nextTitleLabel;
@property (nonatomic) UIView *nextView;
@property (nonatomic) CBPWordPressPost *post;
@property (nonatomic) UIBarButtonItem *postCommentButton;
@property (nonatomic) UIBarButtonItem *previousPostButton;
@property (nonatomic, assign) BOOL scrollToMore;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSURL *url;
@property (nonatomic) UIBarButtonItem *viewCommentsButton;
@property (nonatomic) UIWebView *webView;
@end

@implementation CBPPostViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        _baseFontSize = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize;
    }
    
    return self;
}

- (instancetype)initWithPost:(CBPWordPressPost *)post
{
    self = [self initWithNibName:nil bundle:nil];
    
    if (self) {
        _post = post;
    }
    
    return self;
}

- (instancetype)initWithPost:(CBPWordPressPost *)post withDataSource:(CBPWordPressDataSource *)dataSource withIndex:(NSInteger)index
{
    self = [self initWithPost:post];
    
    if (self) {
        _dataSource = dataSource;
        _index = index;
    }
    
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [self initWithNibName:nil bundle:nil];
    
    if (self) {
        _url = url;
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.nextView];
    
    [self.view addSubview:self.webView];
    
    self.scrollView = self.webView.scrollView;
    self.scrollView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.post) {
        [self displayPost];
    } else if (self.url) {
        [self loadPost];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.post) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    
    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior
                         context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [self.scrollView removeObserver:self
                         forKeyPath:@"contentOffset"
                            context:NULL];
}

- (void)toolbarButtons
{
    NSMutableArray *buttons = @[].mutableCopy;
    
    self.viewCommentsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                            target:self
                                                                            action:@selector(viewCommentAction)];
    [buttons addObject:self.viewCommentsButton];
    self.viewCommentsButton.enabled = NO;
    
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    self.nextPostButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"up4-25"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(nextPostAction)];
    self.nextPostButton.enabled = NO;
    [buttons addObject:self.nextPostButton];
    
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    self.previousPostButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"down4-25"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(previousPostAction)];
    self.previousPostButton.enabled = NO;
    [buttons addObject:self.previousPostButton];
    
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    self.postCommentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                           target:self
                                                                           action:@selector(composeCommentAction)];
    [buttons addObject:self.postCommentButton];
    self.postCommentButton.enabled = NO;
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    

    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                           target:self
                                                                           action:@selector(sharePostAction)];
    [buttons addObject:share];
    
    [self setToolbarItems:buttons animated:YES];
}

#pragma mark -
- (void)displayPost
{
    [self.webView loadHTMLString:[NSString cbp_HTMLStringFor:self.post] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    
    [self updateToolbar];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)loadPost
{
    __weak typeof(self) weakSelf = self;
    
    [NSURLSessionDataTask fetchPostWithURL:self.url
                                 withBlock:^(CBPWordPressPost *post, NSError *error) {
                                         if (!error) {
                                             __strong typeof(weakSelf) strongSelf = weakSelf;
                                             
                                             strongSelf.post = post;
                                             
                                             [strongSelf displayPost];
                                         } else {
                                             NSLog(@"Error: %@", error);
                                            
                                         }
                                     }];
}

- (void)updateToolbar
{
    if (![self.toolbarItems count]) {
        [self toolbarButtons];
    }
    
    BOOL previousEnabled = NO;
    BOOL nextEnabled = NO;
    if (self.dataSource) {
        if (self.index) {
            nextEnabled = YES;
        }
        
        if (self.index < [self.dataSource.posts count]) {
            previousEnabled = YES;
        } else if (self.index == ([self.dataSource.posts count] - 1)) {
            if (self.post.previousTitle) {
                previousEnabled = YES;
            }
        }
    } else {
        if (self.post.nextTitle) {
            nextEnabled = YES;
        }
        
        if (self.post.previousTitle) {
            previousEnabled = YES;
        }
    }
    
    self.previousPostButton.enabled = previousEnabled;
    self.nextPostButton.enabled = nextEnabled;
    
    self.postCommentButton.enabled = ([self.post.commentStatus isEqualToString:@"open"]);
    
    self.viewCommentsButton.enabled = (self.post.commentCount) ? YES : NO;
}

#pragma mark - Button Actions
- (void)composeCommentAction
{
    __weak typeof(self) blockSelf = self;
    
    CBPComposeCommentViewController *vc = [[CBPComposeCommentViewController alloc] initWithPostId:self.post.postId
                                                                              withCompletionBlock:^(CBPWordPressComment *comment, NSError *error) {
                                                                                  [blockSelf.navigationController dismissViewControllerAnimated:YES
                                                                                                                                     completion:^() {
                                                                                                                                         
                                                                                                                                         if (error) {
                                                                                                                                             
                                                                                                                                         } else if (comment) {
                                                                                                                                             
                                                                                                                                         }}];
                                                                              }];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)nextPostAction
{
    if (self.dataSource) {
        if (self.index) {
            self.index--;
            
            self.post = self.dataSource.posts[self.index];
            
            [self displayPost];
        }
    }
}

- (void)previousPostAction
{
    if (self.dataSource) {
        if (self.index < ([self.dataSource.posts count] - 1)) {
            self.index++;
            
            self.post = self.dataSource.posts[self.index];
            
            [self displayPost];
        }
    }
}

- (void)sharePostAction
{
    WhatsAppMessage *whatsappMsg = [[WhatsAppMessage alloc] initWithMessage:[NSString stringWithFormat:@"%@ %@", self.post.title, self.post.url] forABID:nil];
    
    NSArray* activityItems = @[ self.post.title, [NSURL URLWithString:self.post.url], whatsappMsg ];
    
    UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[[JBWhatsAppActivity new], [GPPShareActivity new]]];
    
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypePostToTencentWeibo ];
    
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

- (void)showGallery
{
    NSMutableArray *galleryData = @[].mutableCopy;
    
    for (CBPWordPressAttachment *attachment in self.post.attachments) {
        MHGalleryItem *image = [[MHGalleryItem alloc] initWithURL:attachment.url
                                                      galleryType:MHGalleryTypeImage];
        
        [galleryData addObject:image];
    }
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockGallery dismissViewControllerAnimated:YES dismissImageView:nil completion:nil];
        });
        
    };
    [self presentMHGalleryController:gallery animated:YES completion:nil];
}

- (void)viewCommentAction
{
    CBPCommentsViewController *vc = [[CBPCommentsViewController alloc] initWithPost:self.post];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
        //show images in the in-app browser
        if ([[[request URL] host] hasPrefix:@"cf.broadsheet.ie"]) {
            NSArray *parts = [[[request URL] absoluteString] componentsSeparatedByString:@"."];
            
            NSString *ext = [[parts lastObject] lowercaseString];
            
            if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]
                || [ext isEqualToString:@"png"]
                || [ext isEqualToString:@"gif"]) {
                [self showGallery];
            }
        //Capture CBPWordPress links
        } else if ([[[request URL] scheme] hasSuffix:@"cbpwordpress"]) {
            CBPPostListViewController *vc;
            
            if ([[[request URL] host] hasSuffix:@"author"]) {
                vc = [[CBPPostListViewController alloc] initWithAuthorId:[[request URL] port]];
            } else if ([[[request URL] host] hasSuffix:@"category"]) {
                vc = [[CBPPostListViewController alloc] initWithCategoryId:[[request URL] port]];
            } else if ([[[request URL] host] hasSuffix:@"tag"]) {
                vc = [[CBPPostListViewController alloc] initWithTagId:[[request URL] port]];
            }
            
            if (vc) {
                [self.navigationController pushViewController:vc animated:YES];
            }
        //Read More link
        } else if ([[[request URL] absoluteString] hasSuffix:[NSString stringWithFormat:@"%@#more-%ld", self.post.url, (long)self.post.postId]]) {
            __weak typeof(self) weakSelf = self;

            [self.webView stringByEvaluatingJavaScriptFromString:@"loadingMore()"];

            [NSURLSessionDataTask fetchPostWithId:self.post.postId
                                        withBlock:^(CBPWordPressPost *post, NSError *error) {
                                            if (!error) {
                                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                                
                                                strongSelf.post = post;
                                                
                                                [strongSelf displayPost];
                                                
                                                strongSelf.scrollToMore = YES;
                                            } else {
                                                NSLog(@"Error: %@", error);
                                            }
                                        }];

        //Capture links to other posts
        } else if ([[[request URL] host] hasSuffix:@"broadsheet.ie"] && [[[request URL] path] hasPrefix:@"/20"]) {
            CBPPostViewController *vc = [[CBPPostViewController alloc] initWithURL:[request URL]];
            
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            TOWebViewController *webBrowser = [[TOWebViewController alloc] initWithURL:request.URL];
            [self.navigationController pushViewController:webBrowser animated:YES];
        }
        
        return NO;
	}
    
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.scrollToMore) {
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollIntoView(%ld)", self.post.postId]];
        
        self.scrollToMore = NO;
    }
}

#pragma mark - UIPinchGestureRecognizer
- (void)pinchAction:(UIPinchGestureRecognizer *)gestureRecognizer
{
    CGFloat pinchScale = gestureRecognizer.scale;
    
    if (pinchScale < 1)
    {
        self.baseFontSize = self.baseFontSize - (pinchScale / 1.5f);
    }
    else
    {
        self.baseFontSize = self.baseFontSize + (pinchScale / 2);
    }
    
    if (self.baseFontSize < 16.0f)
    {
        self.baseFontSize = 16.0f;
    }
    else if (self.baseFontSize >= 32.0f)
    {
        self.baseFontSize = 32.0f;
    }
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"changeFontSize('%f')", self.baseFontSize]];
}

#pragma mark - Observers
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"])
    {

    }
}

#pragma mark -
- (UILabel *)nextTitleLabel
{
    if (_nextTitleLabel) {
        _nextTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0, CGRectGetWidth(self.view.frame) - 20.0f, CBPLoadPostViewHeight)];
        _nextTitleLabel.backgroundColor = [UIColor clearColor];
        _nextTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _nextTitleLabel.numberOfLines = 2;
        _nextTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _nextTitleLabel;
}

- (UIView *)nextView
{
    if (!_nextView) {
        _nextView = [[UIView alloc] initWithFrame:CGRectMake(0, -CBPLoadPostViewHeight, CGRectGetWidth(self.view.frame), CBPLoadPostViewHeight)];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = _nextView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.0f] CGColor], nil];
        [_nextView.layer insertSublayer:gradient atIndex:0];
        
        [_nextView addSubview:self.nextTitleLabel];
        
        UIView *bottomBlackLine = [[UIView alloc] initWithFrame:CGRectMake(0, CBPLoadPostViewHeight - 1, CGRectGetWidth(self.view.frame), 1.0f)];
        bottomBlackLine.backgroundColor = [UIColor lightGrayColor];
        [_nextView addSubview:bottomBlackLine];
    }
    
    return _nextView;
}

- (UIWebView *)webView
{
    if (!_webView) {
        //this is to allow video to use sound even if the ute button is toggled
        //via: http://stackoverflow.com/a/12414719/806442
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        BOOL ok;
        NSError *setCategoryError = nil;
        ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
                                 error:&setCategoryError];
        if (!ok) {
            NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
        }
        
        _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.allowsInlineMediaPlayback = YES;
        _webView.mediaPlaybackRequiresUserAction = YES;
        _webView.delegate = self;
        
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(pinchAction:)];
        
        [_webView addGestureRecognizer:pinch];
    }
    
    return _webView;
}
@end
