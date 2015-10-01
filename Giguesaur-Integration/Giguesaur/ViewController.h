//
//  The initial ViewController called when Giguesaur starts. 
//
//  Created by Shahne on 4/9/15.
//

#import <UIKit/UIKit.h>
#import "GameController.h"
#import "BrowsingDelegate.h"

@class BrowsingDelegate; //Weird trick to fix circular dependency issue.

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *name;
@property int xLocation;
@property BrowsingDelegate *delegate;
//@property Vision *vision;
@property Graphics *graphics;

-(void)addButton:(NSString*)title;
-(void)switchViews:(NSString *)address;

@end

