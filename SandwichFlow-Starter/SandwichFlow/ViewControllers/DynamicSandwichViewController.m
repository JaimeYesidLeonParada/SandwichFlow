//
//  DynamicSandwichViewController.m
//  SandwichFlow
//
//  Created by Jaime Yesid Leon Parada on 9/12/14.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

#import "DynamicSandwichViewController.h"
#import "SandwichViewController.h"
#import "AppDelegate.h"

@interface DynamicSandwichViewController () <UICollisionBehaviorDelegate>
{
    NSMutableArray *_views;
    UIGravityBehavior *_gravity;
    UIDynamicAnimator *_animator;
    CGPoint _previousTocuhPoint;
    UISnapBehavior *_snap;
    BOOL _viewDocked;
    BOOL _draggingView;
}
@end

@implementation DynamicSandwichViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    
    _animator = [[UIDynamicAnimator alloc]initWithReferenceView:self.view];
    _gravity = [UIGravityBehavior new];
    [_animator addBehavior:_gravity];
    _gravity.magnitude = 4.0f;
    
    [self addSubViews];
}


#pragma mark - Utils

- (void)setupView
{
    /*
    UIImageView *backgroundImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
    [self.view addSubview:backgroundImageView];
    
    UIImageView *header = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
    header.center = CGPointMake(220, 190);
    [self.view addSubview:header];
    */
    UIImageView *backgroundImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
    backgroundImageView.frame = CGRectInset(self.view.frame, -50.0f, -50.0f);
    [self.view addSubview:backgroundImageView];
    
    [self addMotionEffectToView:backgroundImageView magnitude:50.0f];
    
    UIImageView *midlayerImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Background-MidLayer.png"]];
    [self.view addSubview:midlayerImageView];
    
    UIImageView *header = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
    header.center = CGPointMake(220, 190);
    [self.view addSubview:header];
    [self addMotionEffectToView:header magnitude:-20.f];
}

- (void)addSubViews
{
    _views = [NSMutableArray new];
    __block CGFloat offset = 250.0f;
    
    [[self sandwiches] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_views addObject:[self addRecepieAtOffset:offset forSandwich:obj]];
        offset -= 50.0f;
    }];
}


- (NSArray*)sandwiches
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    return appDelegate.sandwiches;
}

- (UIView*)addRecepieAtOffset:(CGFloat)offset
                  forSandwich:(NSDictionary*)sandwich
{
    CGRect frameFromView = CGRectOffset(self.view.bounds, 0.0, self.view.bounds.size.height - offset);
    
    UIStoryboard *mystoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    SandwichViewController *viewController = [mystoryboard instantiateViewControllerWithIdentifier:@"SandwichVC"];
    
    UIView *view = viewController.view;
    view.frame = frameFromView;
    viewController.sandwich = sandwich;
    
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    
    [viewController didMoveToParentViewController:self];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                         action:@selector(handlePan:)];
    [viewController.view addGestureRecognizer:pan];
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc]initWithItems:@[view]];
    [_animator addBehavior:collision];
    
    CGFloat boundary = view.frame.origin.y + view.frame.size.height + 1;
    
    CGPoint boundaryStart = CGPointMake(0.0, boundary);
    CGPoint boundaryEnd = CGPointMake(self.view.bounds.size.width, boundary);
    
    [collision addBoundaryWithIdentifier:@1
                               fromPoint:boundaryStart
                                 toPoint:boundaryEnd];
    
    boundaryStart = CGPointMake(0.0, 0.0);
    boundaryEnd = CGPointMake(self.view.bounds.size.width, 0.0);
    
    [collision addBoundaryWithIdentifier:@2
                               fromPoint:boundaryStart
                                 toPoint:boundaryEnd];
    collision.collisionDelegate = self;
    
    
    [_gravity addItem:view];
    
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc]initWithItems:@[view]];
    [_animator addBehavior:itemBehavior];
    
    
    return view;
}

- (UIDynamicItemBehavior *)itemBehaviourForView:(UIView*)view
{
    for (UIDynamicItemBehavior *behaviour in _animator.behaviors)
    {
        if (behaviour.class ==[UIDynamicItemBehavior class] && [behaviour.items firstObject]== view){
            return behaviour;
        }
    }
    return nil;
}

- (void)addVelocityToView:(UIView*)view fromGesture:(UIPanGestureRecognizer*)gesture
{
    CGPoint vel = [gesture velocityInView:self.view];
    vel.x = 0;
    UIDynamicItemBehavior *behaviour = [self itemBehaviourForView:view];
    [behaviour addLinearVelocity:vel forItem:view];
}

- (void)tryDockView:(UIView*)view
{
    BOOL viewHasReachedDockLocation = view.frame.origin.y < 100.0;
    
    if (viewHasReachedDockLocation){
        if (!_viewDocked){
            _snap = [[UISnapBehavior alloc]initWithItem:view
                                            snapToPoint:self.view.center];
            [_animator addBehavior:_snap];
            [self setAlphaWhenViewDocked:view alpha:0.0];
            _viewDocked = YES;
        }
    }else{
        if (_viewDocked){
            [_animator removeBehavior:_snap];
            [self setAlphaWhenViewDocked:view alpha:1.0];
            _viewDocked = NO;
        }
    }
}

- (void)setAlphaWhenViewDocked:(UIView*)view alpha:(CGFloat)alpha
{
    [_views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *aView = (UIView*)obj;
        if (aView != view){
            [UIView animateWithDuration:1.0 animations:^{
                aView.alpha = alpha;
            }];
        }
    }];
}

- (void)addMotionEffectToView:(UIView*)view
                    magnitude:(CGFloat)magnitude
{
    UIInterpolatingMotionEffect *xMotion = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xMotion.minimumRelativeValue = @(-magnitude);
    xMotion.maximumRelativeValue = @(magnitude);
    
    UIInterpolatingMotionEffect *yMotion = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yMotion.minimumRelativeValue = @(-magnitude);
    yMotion.maximumRelativeValue = @(magnitude);
    
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[xMotion, yMotion];
    [view addMotionEffect:group];
}

#pragma mark - Selector GestureReconizer

- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
    CGPoint touchPoint = [gesture locationInView:self.view];
    UIView *draggedView = gesture.view;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint dragStartLocation = [gesture locationInView:draggedView];
        if (dragStartLocation.y < 200.0f){
            _draggingView = YES;
            _previousTocuhPoint = touchPoint;
        }
    }else if (gesture.state == UIGestureRecognizerStateChanged && _draggingView)
    {
        CGFloat yOffset = _previousTocuhPoint.y - touchPoint.y;
        gesture.view.center = CGPointMake(draggedView.center.x, draggedView.center.y - yOffset);
        _previousTocuhPoint = touchPoint;
    }else if (gesture.state == UIGestureRecognizerStateEnded && _draggingView)
    {
        [self tryDockView:draggedView];
        [self addVelocityToView:draggedView fromGesture:gesture];
        [_animator updateItemUsingCurrentState:draggedView];
        _draggingView = NO;
    }
}

#pragma mark UICollisionBehaviorDelegate

- (void)collisionBehavior:(UICollisionBehavior *)behavior
      beganContactForItem:(id<UIDynamicItem>)item
   withBoundaryIdentifier:(id<NSCopying>)identifier
                  atPoint:(CGPoint)p
{
    if ([@2 isEqual:identifier]){
        UIView *view = (UIView*)item;
        [self tryDockView:view];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
