//
//  ViewController.m
//  ModelFactory
//
//  Created by Johnson on 6/8/15.
//  Copyright (c) 2015 Johnson. All rights reserved.
//

#import "ViewController.h"

#define SAVE_PATH       [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]

#define Library_PATH     [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey]]
#define DATA_PATH        [Library_PATH stringByAppendingPathComponent:[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey]]

#define STRING_WITH_SIZE_AND_DEFAULT_HEIGHT(string, font, width) [string boundingRectWithSize:CGSizeMake(width, NSIntegerMax) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size
#define EmptyString     @""

@interface ViewController ()

@property (unsafe_unretained) IBOutlet NSTextView *textViewResponse;
@property (weak) IBOutlet NSTextField *textFieldResponsePlaceholder;
@property (unsafe_unretained) IBOutlet NSTextView *textViewCreate;
@property (weak) IBOutlet NSTextField *textFieldCreatePlaceholder;


@property (weak) IBOutlet NSTextField *textFieldCompany;
@property (weak) IBOutlet NSTextField *textFieldAuthor;
@property (weak) IBOutlet NSTextField *textFieldProject;
@property (weak) IBOutlet NSTextField *textFieldSavePath;

@property (weak) IBOutlet NSTextField *textFieldSuperClass;
@property (weak) IBOutlet NSTextField *textFieldClassName;
@property (weak) IBOutlet NSTextField *textFieldImportHeader;
@property (weak) IBOutlet NSTextField *textFieldReferenceType;

@property (weak) IBOutlet NSTextField *textFieldLink;

@property (weak) IBOutlet NSMatrix *matrixRadio;

@property (nonatomic, strong) NSTextField *textFieldHud;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:nil];
    
    self.textFieldSavePath.stringValue = SAVE_PATH;
    [self.matrixRadio selectCellAtRow:0 column:1];
    
    [self readDataFromLocal];
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - Notification
- (void)textViewDidChangeSelection:(NSNotification *)noti
{
    [noti.object isEqual:self.textViewCreate]
    ?
    (self.textFieldCreatePlaceholder.hidden = ![self.textViewCreate.string isEqualToString:EmptyString])
    :
    (self.textFieldResponsePlaceholder.hidden = ![self.textViewResponse.string isEqualToString:EmptyString]);
}

#pragma mark - Click
- (IBAction)clickRequest:(id)sender {
    if ([self.textFieldLink.stringValue isEqualToString:EmptyString]) {
        [self showHudForText:@"请求链接不能为空" delay:1.f];
        return;
    }
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.textFieldLink.stringValue]] queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        self.textViewResponse.string = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:NULL] description];
    }];
}

- (IBAction)clickCreateModelAndExport:(id)sender {
    if ([self.textViewCreate.string isEqualToString:EmptyString]) {
        [self showHudForText:@"生成内容不能为空" delay:1.f];
        return;
    }
    [self createModelForDictionary:[self createModelDictionary:self.textViewCreate.string remark:!self.matrixRadio.selectedColumn]
                        forCompany:self.textFieldCompany.stringValue
                     forSuperClass:NSClassFromString(self.textFieldSuperClass.stringValue)
                      forClassName:self.textFieldClassName.stringValue
                   forImportHeader:self.textFieldImportHeader.stringValue
                  forReferenceType:self.textFieldReferenceType.stringValue
                         forAuthor:self.textFieldAuthor.stringValue
                        forProject:self.textFieldProject.stringValue
                       forSavePath:self.textFieldSavePath.stringValue];
}

#pragma mark - Methods
- (void)readDataFromLocal
{
    NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:DATA_PATH];
    if (dictionary) {
        self.textFieldCompany.stringValue = dictionary[@"textFieldCompany"];
        self.textFieldSuperClass.stringValue = dictionary[@"textFieldSuperClass"];
        self.textFieldClassName.stringValue = dictionary[@"textFieldClassName"];
        self.textFieldImportHeader.stringValue = dictionary[@"textFieldImportHeader"];
        self.textFieldReferenceType.stringValue = dictionary[@"textFieldReferenceType"];
        self.textFieldAuthor.stringValue = dictionary[@"textFieldAuthor"];
        self.textFieldProject.stringValue = dictionary[@"textFieldProject"];
        self.textFieldSavePath.stringValue = dictionary[@"textFieldSavePath"];
    }
}

- (void)saveCurrentData
{
    NSDictionary *dictionary = @{
                                 @"textFieldCompany": self.textFieldCompany.stringValue,
                                 @"textFieldSuperClass": self.textFieldSuperClass.stringValue,
                                 @"textFieldClassName": self.textFieldClassName.stringValue,
                                 @"textFieldImportHeader": self.textFieldImportHeader.stringValue,
                                 @"textFieldReferenceType": self.textFieldReferenceType.stringValue,
                                 @"textFieldAuthor": self.textFieldAuthor.stringValue,
                                 @"textFieldProject": self.textFieldProject.stringValue,
                                 @"textFieldSavePath": self.textFieldSavePath.stringValue,
                                 };
    if (![[NSFileManager defaultManager] fileExistsAtPath:Library_PATH]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:Library_PATH withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    [NSKeyedArchiver archiveRootObject:dictionary toFile:[Library_PATH stringByAppendingPathComponent:[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey]]];
}

- (NSDictionary *)createModelDictionary:(NSString *)string remark:(BOOL)remark;
{
    if (!string || [string isEqualToString:EmptyString]) {
        return nil;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:EmptyString];
    NSString *lastChar = [[string componentsSeparatedByString:@"\n"] firstObject];
    //是否是JSON片段
    BOOL isJSON = [[lastChar substringFromIndex:lastChar.length > 0 ? lastChar.length - 1 : 0] isEqualToString:@","];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:EmptyString];
    
    [[string componentsSeparatedByString:isJSON ? @"," : @";"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        obj = [obj stringByReplacingOccurrencesOfString:@"\"" withString:EmptyString];
        NSArray *array = [obj componentsSeparatedByString:isJSON ? @":" : @"="];
        [array.firstObject isEqualToString:EmptyString] ? nil : [dictionary setObject:remark ? array.lastObject : EmptyString forKey:array.firstObject];
    }];
    return dictionary;
}

- (void)createModelForDictionary:(NSDictionary *)info
               forCompany:(NSString *)company
                forSuperClass:(Class)superClass
                 forClassName:(NSString *)className
              forImportHeader:(NSString *)importHeader
             forReferenceType:(NSString *)referenceType
                    forAuthor:(NSString *)author
                   forProject:(NSString *)project
                  forSavePath:(NSString *)savePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString *date = [formatter stringFromDate:[NSDate date]];
    
    NSString *header_h = [NSString stringWithFormat:@"//\n//  %@.h\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright (c) %@. All rights reserved.\n//\n\n", className, project, author, date, company];
    
    NSMutableString *string_h = [NSMutableString stringWithFormat:@"%@%@\n\n@interface %@ : %@\n", header_h, importHeader, className, NSStringFromClass(superClass)];
    [[info allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [info[obj] isEqualToString:EmptyString] ? [string_h appendString:@"\n"] : [string_h appendFormat:@"\n/**%@*/\n", info[obj]];
        [string_h appendFormat:@"@property (nonatomic, %@) NSString *%@;\n", referenceType, obj];
    }];
    [string_h appendString:@"\n@end"];
    
    NSString *header_m = [NSString stringWithFormat:@"//\n//  %@.m\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright (c) %@. All rights reserved.\n//\n\n", className, project, author, date, company];
    
    NSString *string_m = [NSString stringWithFormat:@"%@#import \"%@.h\"\n\n@implementation %@\n\n@end", header_m, className, className];
    
    NSString *path = [savePath stringByAppendingPathComponent:className];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathExtension:@"h"]]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"提示";
        alert.informativeText = @"该模型已存在,是否覆盖?";
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert beginSheetModalForWindow:(id)self.nextResponder completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == 1000) {
                [string_h writeToFile:[path stringByAppendingPathExtension:@"h"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                [string_m writeToFile:[path stringByAppendingPathExtension:@"m"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                [self saveCurrentData];
            }
        }];
    }else {
        [string_h writeToFile:[path stringByAppendingPathExtension:@"h"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [string_m writeToFile:[path stringByAppendingPathExtension:@"m"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [self saveCurrentData];
    }
}

- (void)hideHud
{
    [self.textFieldHud setHidden:YES];
}

- (void)showHudForText:(NSString *)text delay:(NSTimeInterval)delay;
{
    self.textFieldHud.stringValue = text;
    [self.textFieldHud setHidden:NO];
    
    CGRect frame = [self.textFieldHud.stringValue boundingRectWithSize:CGSizeMake(self.view.bounds.size.width, NSIntegerMax) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: self.textFieldHud.font}];
    frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2;
    frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2;
    frame.size.width = frame.size.width + 5;
    self.textFieldHud.frame = frame;
    
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(hideHud) userInfo:nil repeats:NO];
}

#pragma mark - GetMethods
- (NSTextField *)textFieldHud
{
    if (!_textFieldHud) {
        _textFieldHud = [NSTextField new];
        _textFieldHud.drawsBackground = YES;
        _textFieldHud.font = [NSFont systemFontOfSize:33];
        _textFieldHud.bordered = NO;
        _textFieldHud.selectable = NO;
        _textFieldHud.layer.cornerRadius = 11;
        _textFieldHud.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.5];
        [self.view addSubview:_textFieldHud];
    }
    return _textFieldHud;
}
@end
