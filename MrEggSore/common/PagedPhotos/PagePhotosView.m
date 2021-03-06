//
//  PagePhotosView.m
//  picMemory
//
//  Created by simon on 12-6-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PagePhotosView.h"
#import "UIImageView+WebCache.h"
@implementation PagePhotosView
@synthesize dataSource;
@synthesize imageViews;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame withDataSource:(id<PagePhotosDataSource>)_dataSource {
    if ((self = [super initWithFrame:frame])) {

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleTap];
//        //添加图片长按响应
//        UILongPressGestureRecognizer *longPressReger = [[UILongPressGestureRecognizer alloc]
//        initWithTarget:self action:@selector(LongPressed:)];
//        [self addGestureRecognizer:longPressReger];
        
		self.dataSource = _dataSource;
        // Initialization UIScrollView
		int pageControlHeight = 20;
		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, frame.size.height - pageControlHeight, frame.size.width, pageControlHeight)];
		[self addSubview:scrollView];
		[self addSubview:pageControl];
        lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, frame.size.height - pageControlHeight-40, frame.size.width-10*2,40)];
		lblTitle.backgroundColor = getColor(6, 6, 6, 0.4);
        lblTitle.textColor = [UIColor whiteColor];
        lblTitle.font = [UIFont systemFontOfSize:13];
        lblTitle.numberOfLines = 2;
        lblTitle.textAlignment = NSTextAlignmentCenter;
        [self addSubview:lblTitle];

        
		int kNumberOfPages = [dataSource numberOfPages];
		
		// in the meantime, load the array with placeholders which will be replaced on demand
		NSMutableArray *views = [[NSMutableArray alloc] init];
		for (unsigned i = 0; i < kNumberOfPages; i++) {
			[views addObject:[NSNull null]];
		}
		self.imageViews = views;
		//[views release];
		
		// a page is the width of the scroll view
		scrollView.pagingEnabled = YES;
		scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.scrollsToTop = NO;
		scrollView.delegate = self;
        //[[[scrollView subviews] objectAtIndex:0] removeFromSuperview];
		
		pageControl.numberOfPages = kNumberOfPages;
		pageControl.currentPage = 0;
		pageControl.backgroundColor = [UIColor clearColor];

		// pages are created on demand
		// load the visible page
		// load the page on either side to avoid flashes when the user starts scrolling
        int total = [dataSource numberOfPages];
        for(int i=0;i<total;++i)
        {
            [self loadScrollViewWithPage:i];
        }
		lastMark = total-1;
        firstMark = 0;
    }
    return self;
}
#pragma mark - ff

- (void)loadScrollViewWithPage:(int)page {
	int kNumberOfPages = [dataSource numberOfPages];
	
    if (page < 0) return;
    if (page >= kNumberOfPages) return;
	
    // replace the placeholder if necessary
    UIImageView *view = [imageViews objectAtIndex:page];
    if ((NSNull *)view == [NSNull null]) {
//		UIImage *image = [dataSource imageAtIndex:page];
//        view = [[UIImageView alloc] initWithImage:image];
        NSString*imgUrl = [dataSource imgUrlAtIndex:page];
        view = [[UIImageView alloc] init];
        [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
        
        //自适应图片宽高比例
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.tag = page;
        [imageViews replaceObjectAtIndex:page withObject:view];
		//[view release];
    }
	
    // add the controller's view to the scroll view
    if (nil == view.superview) {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        view.frame = frame;
        [scrollView addSubview:view];
    }
}

-(void)refreshCurrentPage
{
    UIImageView *view = [imageViews objectAtIndex:pageControl.currentPage];
    if(view)
    {
        NSString*imgUrl = [dataSource imgUrlAtIndex:pageControl.currentPage];
        [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }
    lblTitle.text = [dataSource titleAtIndex:pageControl.currentPage];
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
//    CGFloat pageWidth = scrollView.frame.size.width;
//    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    [dataSource ImageTaped:pageControl.currentPage];
}

- (void)LongPressed:(UIGestureRecognizer *)gestureRecognizer {  
    if ( gestureRecognizer.state == UIGestureRecognizerStateBegan /*UIGestureRecognizerStateRecognized */) {
        CGFloat pageWidth = scrollView.frame.size.width;
        int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        
        [dataSource ImageLongPress:page];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    UIImageView *view = (UIImageView *)[scrollView.subviews objectAtIndex:page];
    pageControl.currentPage = view.tag;
    
    int x=scrollView.contentOffset.x;
    if(x>=([dataSource numberOfPages]-1)*pageWidth) //往下翻一张
    {
        [self refreshScrollView];
    }
    else if(x<0)
    {
        [self refreshScrollView2];
    }
    [self refreshCurrentPage];
}

- (void) refreshScrollView
{
    NSArray *subViews=[scrollView subviews];
    if([subViews count]!=0)
    {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    int kNumberOfPages = [dataSource numberOfPages];
    int index;
    for(int i=0; i<kNumberOfPages;++i)
    {
        index = [self validPageValue:lastMark-(kNumberOfPages-i-1)+1];
        
        UIImageView *view = [imageViews objectAtIndex:index];
        if ((NSNull *)view == [NSNull null]) {
//            UIImage *image = [dataSource imageAtIndex:index];
//            view = [[UIImageView alloc] initWithImage:image];
            NSString*imgUrl = [dataSource imgUrlAtIndex:index];
            view = [[UIImageView alloc] init];
            [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
            
            //自适应图片宽高比例
            view.contentMode = UIViewContentModeScaleAspectFit;
            view.tag = index;
            [imageViews replaceObjectAtIndex:index withObject:view];
        }
        
        // add the controller's view to the scroll view
        if (nil == view.superview) {
            CGRect frame = scrollView.frame;
            frame.origin.x = frame.size.width * i;
            frame.origin.y = 0;
            view.frame = frame;
//            NSString*imgUrl = [dataSource imgUrlAtIndex:index];
//            [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
            [scrollView addSubview:view];
//            lblTitle.text = [dataSource titleAtIndex:index];

        }
    }
    firstMark = [self validPageValue:lastMark-(kNumberOfPages-0-1)+1];
    lastMark = [self validPageValue:lastMark+1];
    [scrollView setContentOffset:CGPointMake((kNumberOfPages-2)*scrollView.frame.size.width, 0)];
}

- (void) refreshScrollView2
{
    NSArray *subViews=[scrollView subviews];
    if([subViews count]!=0)
    {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    int kNumberOfPages = [dataSource numberOfPages];
    int index;
    for(int i=0; i<kNumberOfPages;++i)
    {
        if(i==0)
        {
            index = [self validPageValue: firstMark-1];
        }
        else if(i==1)
            index = firstMark;
        else
        {
            index = [self validPageValue: firstMark + i - 1];
        }
        UIImageView *view = [imageViews objectAtIndex:index];
        if ((NSNull *)view == [NSNull null]) {
//            UIImage *image = [dataSource imageAtIndex:index];
//            view = [[UIImageView alloc] initWithImage:image];
            NSString*imgUrl = [dataSource imgUrlAtIndex:index];
            view = [[UIImageView alloc] init];
            [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
            //自适应图片宽高比例
            view.contentMode = UIViewContentModeScaleAspectFit;
            view.tag = index;
            [imageViews replaceObjectAtIndex:index withObject:view];
        }
        
        // add the controller's view to the scroll view
        if (nil == view.superview) {
            CGRect frame = scrollView.frame;
            frame.origin.x = frame.size.width * i;
            frame.origin.y = 0;
            view.frame = frame;
//            NSString*imgUrl = [dataSource imgUrlAtIndex:index];
//            [view setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"placeholder"]];
            [scrollView addSubview:view];
//            lblTitle.text = [dataSource titleAtIndex:index];

        }
    }
    lastMark = [self validPageValue: firstMark + (kNumberOfPages-1) - 1];
    firstMark = [self validPageValue: firstMark-1];

    [scrollView setContentOffset:CGPointMake(scrollView.frame.size.width, 0)];
}

- (int)validPageValue:(NSInteger)value
{
    if(value<0)    value+=[dataSource numberOfPages];
    if(value>=[dataSource numberOfPages])  value-=[dataSource numberOfPages];
    return value;
}

@end
