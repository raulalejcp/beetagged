//
//  ContactViewController.m
//  Bees Chest
//
//  Created by Billy Irwin on 1/1/14.
//  Copyright (c) 2014 Arbrr. All rights reserved.
//

#import "ContactViewController.h"

@interface ContactViewController ()
@property (nonatomic, strong) NSMutableArray *deleted;
@property (nonatomic, strong) NSMutableArray *added;
@end

@implementation ContactViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.deleted = [@[] mutableCopy];
        self.added = [@[] mutableCopy];
    }
    return self;
}

#pragma mark View Loading
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tagsCollectionView.delegate = self;
    self.tagsCollectionView.dataSource = self;
    self.tagsCollectionView.backgroundColor = [UIColor clearColor];
    
    [self formatLayout];
    [self typeahead];
    self.contactTags = [self.contact.tags_ mutableCopy];
}

// style the typeahead view
- (void)typeahead {
    float top = 70.0, left = 20.0, height = 180.0;

    self.typeAheadViewController = [[BATypeAheadViewController alloc] initWithFrame:CGRectMake(left, top, self.view.frame.size.width - left * 2, height) andData:[[LinkedInManager singleton] tagOptionsArray]];
    self.typeAheadViewController.delegate = self;
    self.typeAheadViewController.view.layer.cornerRadius = 40.0;
    self.typeAheadViewController.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:.6];
    self.typeAheadViewController.view.tableView.backgroundColor = [UIColor clearColor];
    [self.typeAheadViewController hideView:NO];
    [self addChildViewController:self.typeAheadViewController];
    [self.view addSubview:self.typeAheadViewController.view];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

// save the data to parse before we leave
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // starfish -- make sure data is being updated in parse
//    [PFObject saveAllInBackground:self.added];
//    [PFObject deleteAllInBackground:self.deleted];
}

#pragma mark View Logic
// encapsulating function that writes text in all of the fields and moves the view
// up if no text exists.
- (void)formatLayout {
    CGFloat moved = 0.0;
    
    // 1. set the image and make it a circle
    self.contactImage.layer.cornerRadius = self.contactImage.frame.size.height / 2;
    self.contactImage.clipsToBounds = YES;
	[self.contactImage setImageWithURL:[NSURL URLWithString:self.contact.pictureUrl] placeholderImage:kContactCellPlaceholderImage];
    
    // 2. set the name
    self.nameLabel.text = self.contact.formattedName;
    
    // 3. set the headline
    self.headlineLabel.text = [self getHeadline];
    
    // 4. set the position
    NSString *positionTitle = [self getPositionTitle];
    if (positionTitle.length == 0) {
        moved += [self removeViewOfHeight:self.positionTitleLabel];
    } else {
        self.positionTitleLabel.text = positionTitle;
    }
    
    NSString *positionName = [self getPositionName];
    if (positionName.length == 0) {
        moved += [self removeViewOfHeight:self.positionNameLabel];
    } else {
        [self moveView:self.positionNameLabel upBy:moved andIncreaseHeight:0.0];
        self.positionNameLabel.text = positionName;
    }
    
    // 5. set the description
    NSString *description = self.contact.positionSummary;
    if (description && description.length > 0) {
        [self moveView:self.positionSummaryText upBy:moved andIncreaseHeight:0.0];
        self.positionSummaryText.text = description;
    } else {
        moved += [self removeViewOfHeight:self.positionSummaryText];
    }
    
    // 6. set up the custom tag view (to be implemented)
    [self moveView:self.tagsCollectionView upBy:moved andIncreaseHeight:moved];
}

// gives the headline for the Contact
- (NSString *)getHeadline {
    NSString *headline = @"A good friend with no headline";
    if (self.contact.headline && self.contact.headline.length > 0) {
        headline = self.contact.headline;
    }
    return headline;
}

// gets the title for the position
- (NSString *)getPositionTitle {
    NSString *positionTitle = @"";
    if (self.contact.positionTitle && self.contact.positionTitle.length > 0) {
        positionTitle = self.contact.positionTitle;
    }
    return positionTitle;
}

// gets the name for the position
- (NSString *)getPositionName {
    NSString *positionName = @"";
    if (self.contact.positionName && self.contact.positionName.length > 0) {
        positionName = [NSString stringWithFormat:@"At %@", self.contact.positionName];
    }
    return positionName;
}

// removes a subview from the main view and returns how hight
// the next view needs to move "up" to replace that view.
-(CGFloat)removeViewOfHeight:(UIView *)view {
    CGFloat height = view.frame.size.height;
    [view removeFromSuperview];
    return height;
}

// moves the view up and makes it bigger
- (void)moveView:(UIView *)view upBy:(CGFloat)distance andIncreaseHeight:(CGFloat)increase {
    CGRect f = view.frame;
    [view setFrame:CGRectMake(f.origin.x, f.origin.y - distance, f.size.width, f.size.height + increase)];
}

#pragma mark Button Actions
// action for when you press the picture that sends you to linkedin.com
- (IBAction)goToLinkedInProfile:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.contact.linkedInUrl]];
}

#pragma mark CollectionView
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.contactTags.count + 1;
}

// called when the item is selected - will only do anything if the add button
// is selected
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    // if it's the last item, add a new item
    if (indexPath.item == self.contactTags.count) {
        [self showAddTagView];
    }
}

// style the collectionView cell at the indexPath
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tagCellIdentifier = @"TagCollectionCell";
    TagCell *cell = (TagCell *)[cv dequeueReusableCellWithReuseIdentifier:tagCellIdentifier forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.frame.size.height / 4;
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    NSInteger i = indexPath.item;
    if (i < self.contactTags.count) {
        Tag *tag = self.contactTags[i];
        label.text = tag.attributeName;
        label.textColor = [UIColor yellowColor];
    } else {
        label.text = @"+";
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:50.0];
        float cellHeight = cell.frame.size.height, labelHeight = label.frame.size.height;
        float offset = cellHeight - labelHeight - 3.0;
        label.frame = CGRectMake(0, offset, cell.frame.size.width, labelHeight);
        label.textColor = [UIColor whiteColor];
    }
    return cell;
}

#pragma mark - Tag insert/remove
// adds a Tag object at the indexPath
// adds a Tag object from Core Data
- (void)addTagToCollectionView:(Tag *)tag {
    
    for (Tag *check in self.contactTags) {
        // make sure that there are no duplicates
        if ([check.attributeName isEqualToString:tag.attributeName]) {
            return;
        }
    }

    [self.contactTags addObject:tag];
    [self addedTag:tag];
    [self resetContactTags];
    [self.tagsCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.contactTags.count - 1 inSection:0]]];
}

- (void)resetContactTags {
    LinkedInManager *lim = [LinkedInManager singleton];
    self.contact.tags_ = [self.contactTags copy];
    [lim.managedObjectContext save:nil];
}

// adds the tag to the added changeList
- (void)addedTag:(Tag *)tag {
    for (Tag *t in self.deleted) {
        NSInteger index = 0;
        if ([t.attributeName isEqualToString:tag.attributeName]) {
            [self.deleted removeObjectAtIndex:index];
            return;
        }
        index++;
    }
    [self.added addObject:tag];
}

// adds the tag to the deleted changeList
- (void)deletedTag:(Tag *)tag {
    for (Tag *t in self.added) {
        NSInteger index = 0;
        if ([t.attributeName isEqualToString:tag.attributeName]) {
            [self.added removeObjectAtIndex:index];
            return;
        }
        index++;
    }
    [self.deleted addObject:tag];
}

// deletes a Tag object at the indexPath
// deletes a Tag object from Core Data
- (void)deleteTagAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.contactTags objectAtIndex:indexPath.item];
    [self.contactTags removeObjectAtIndex:indexPath.item];
    [self deletedTag:tag];
    [self resetContactTags];
    [self.tagsCollectionView deleteItemsAtIndexPaths:@[indexPath]];
}

// This is is what brings the typeahead view onto the screen and shows the
// the keyboard
- (void)showAddTagView {
    [self.typeAheadViewController showView:YES];
}

// This is the delegate method that is called when on of the items from the
// typeahead is chosen.  It dimisses the keyboard, moves the view offscreen,
// and adds the tag to the collectionView
- (void)cellClickedWithData:(id)data {
    LinkedInManager *lim = [LinkedInManager singleton];
    Tag *t = [Tag tagFromTagOption:(TagOption *)data taggedUser:self.contact.linkedInId byUser:[lim currenUserId]];

    // 1. make the view go away.
    [self.typeAheadViewController hideView:YES];
    
    // 2. add the Tag
    [self addTagToCollectionView:t];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
