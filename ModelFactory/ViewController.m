//
//  ViewController.m
//  ModelFactory
//
//  Created by Johnson on 6/8/15.
//  Copyright (c) 2015 Johnson. All rights reserved.
//

#import "ViewController.h"
#import "SSZipArchive.h"

#define SAVE_PATH       [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]

#define Library_PATH     [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey]]

#define DATA_PATH        [Library_PATH stringByAppendingPathComponent:[[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey]]
#define GEMS_PATH        [Library_PATH stringByAppendingPathComponent:@"gems"]

#define STRING_WITH_SIZE_AND_DEFAULT_HEIGHT(string, font, width) [string boundingRectWithSize:CGSizeMake(width, NSIntegerMax) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size

#define EmptyString     @""
#define FieldSeparator  @"Johnson"

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

+ (void)load
{
    [super load];
    if (![[NSFileManager defaultManager] fileExistsAtPath:GEMS_PATH]) {
        [SSZipArchive unzipFileAtPath:[[NSBundle mainBundle] pathForResource:@"gems" ofType:@"zip"] toDestination:Library_PATH];
    }
    NSLog(@"本地gem路径:->  %@",GEMS_PATH);
}

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
        id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:NULL];
        if (!object) {
            [self showHudForText:response.description delay:3.f];
        }
        self.textViewResponse.string = object ? [object description] : EmptyString;
    }];
}

- (IBAction)clickCreateModelAndExport:(id)sender {
    if ([self.textViewCreate.string isEqualToString:EmptyString]) {
        [self showHudForText:@"生成内容不能为空" delay:1.f];
        return;
    }
    else if (![[NSFileManager defaultManager] fileExistsAtPath:self.textFieldSavePath.stringValue] || ![self.textFieldSavePath.stringValue hasSuffix:@"xcodeproj"]) {
        [self showHudForText:@"请填写正确的xcodeproj" delay:1.f];
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
                  forXcodeProjName:[self getXcodeprojName:self.textFieldSavePath.stringValue]
                       forSavePath:[self getSavePathFromProjPath:self.textFieldSavePath.stringValue]];
}

#pragma mark - Methods
/**根据传入的xcodeproj可执行文件路径重新给脚本文件命名(xcodeproj_Model)*/
- (NSString *)getXcodeprojName:(NSString *)xcodeProjPath
{
    return [[[[[xcodeProjPath componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"."] firstObject] stringByAppendingFormat:@"_%@.rb", self.textFieldClassName.stringValue];
}

/**根据传入的xcodeproj可执行文件路径获取Model的路径*/
- (NSString *)getSavePathFromProjPath:(NSString *)xcodeProjPath
{
    NSRange range = [xcodeProjPath rangeOfString:[[xcodeProjPath componentsSeparatedByString:@"/"] lastObject]];
    NSString *basePath = [xcodeProjPath substringToIndex:range.location];
    NSArray *arraySubFoldersAndFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:NULL];
    NSString __block *savePath = nil;
    [arraySubFoldersAndFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        savePath = [basePath stringByAppendingPathComponent:obj];
        BOOL flag;[[NSFileManager defaultManager] fileExistsAtPath:savePath isDirectory:&flag];
        if (flag && ![obj hasSuffix:@"Tests"] && [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:savePath error:NULL] containsObject:@"main.m"]) {
            *stop = YES;
        }
    }];
    return savePath;
}

/**读取填写数据*/
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

/**保持填写数据*/
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

/**制作创建Model的字典*/
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
        [array.firstObject isEqualToString:EmptyString] ? nil : [dictionary setObject:remark ? array.lastObject : EmptyString forKey:[NSString stringWithFormat:@"%@%@%@", @(idx), FieldSeparator, array.firstObject]];
    }];
    return dictionary;
}

- (NSString *)createProperty:(NSDictionary *)info forReferenceType:(NSString *)referenceType
{
    NSMutableString *stringContext = [NSMutableString stringWithString:@"\n"];
    [[[info allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return ([[obj1 componentsSeparatedByString:FieldSeparator].firstObject integerValue] < [[obj2 componentsSeparatedByString:FieldSeparator].firstObject integerValue]) ? NSOrderedAscending : NSOrderedDescending;
    }] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [info[obj] isEqualToString:EmptyString] ? [stringContext appendString:@"\n"] : [stringContext appendFormat:@"\n/**%@*/\n", info[obj]];
        obj = [obj componentsSeparatedByString:FieldSeparator].lastObject;
        [stringContext appendFormat:@"@property (nonatomic, %@) NSString *%@;\n", referenceType, obj];
    }];
    [stringContext appendString:@"\n"];
    return stringContext ?: EmptyString;
}

/**创建Model*/
- (void)createModelForDictionary:(NSDictionary *)info
               forCompany:(NSString *)company
                forSuperClass:(Class)superClass
                 forClassName:(NSString *)className
              forImportHeader:(NSString *)importHeader
             forReferenceType:(NSString *)referenceType
                    forAuthor:(NSString *)author
                   forProject:(NSString *)project
             forXcodeProjName:(NSString *)xcodeProjName
                  forSavePath:(NSString *)savePath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString *date = [formatter stringFromDate:[NSDate date]];
    
    NSString *header_h = [NSString stringWithFormat:@"//\n//  %@.h\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright (c) %@. All rights reserved.\n//\n\n", className, project, author, date, company];
    
    NSMutableString *string_h = [NSMutableString stringWithFormat:@"%@%@\n\n@interface %@ : %@", header_h, importHeader, className, NSStringFromClass(superClass)];
    
    [string_h appendString:[self createProperty:info forReferenceType:referenceType]];
    
    [string_h appendString:@"@end"];
    
    NSString *header_m = [NSString stringWithFormat:@"//\n//  %@.m\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright (c) %@. All rights reserved.\n//\n\n", className, project, author, date, company];
    
    NSString *string_m = [NSString stringWithFormat:@"%@#import \"%@.h\"\n\n@implementation %@\n\n@end", header_m, className, className];

    NSString *path_h = [[savePath stringByAppendingPathComponent:className] stringByAppendingPathExtension:@"h"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path_h]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"(•̀⌄•́)";
        alert.informativeText = @"该模型已存在";
        alert.alertStyle = NSCriticalAlertStyle;
        [alert addButtonWithTitle:@"覆盖"];
        [alert addButtonWithTitle:@"追加"];
        [alert addButtonWithTitle:@"取消"];
        [alert beginSheetModalForWindow:(id)self.nextResponder completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == 1000) {//覆盖
                [self createModelFileAndExecuteScript:string_h string_m:string_m className:className xcodeProjName:xcodeProjName savePath:savePath];
            }else if (returnCode == 1001) {//追加
                NSMutableString *string_h_old = [[NSMutableString alloc] initWithContentsOfFile:path_h encoding:NSUTF8StringEncoding error:NULL];

                NSMutableArray *array_properties_old = [NSMutableArray array];
                [[string_h_old componentsSeparatedByString:@";"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [array_properties_old addObject:[[obj componentsSeparatedByString:@"*"] lastObject]];
                }];
                [array_properties_old removeLastObject];
                
                NSMutableDictionary *new_info = [NSMutableDictionary dictionaryWithDictionary:info];
                [new_info enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSString *propertyString = [key componentsSeparatedByString:FieldSeparator].lastObject;
                    [array_properties_old containsObject:propertyString] ? [new_info removeObjectForKey:key] : nil;
                }];
                
                [string_h_old insertString:[self createProperty:new_info forReferenceType:referenceType] atIndex:[string_h_old rangeOfString:@"@end"].location];
                
                [self createModelFileAndExecuteScript:string_h_old string_m:string_m className:className xcodeProjName:xcodeProjName savePath:savePath];
            }
        }];
    }else {
        [self createModelFileAndExecuteScript:string_h string_m:string_m className:className xcodeProjName:xcodeProjName savePath:savePath];
    }
}

/**创建Model文件至目标项目,并执行脚本添加项目引用,并删除脚本文件*/
- (void)createModelFileAndExecuteScript:(NSString *)string_h string_m:(NSString *)string_m className:(NSString *)className xcodeProjName:(NSString *)xcodeProjName savePath:(NSString *)savePath
{
    NSString *path = [savePath stringByAppendingPathComponent:className];
    [string_h writeToFile:[path stringByAppendingPathExtension:@"h"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [string_m writeToFile:[path stringByAppendingPathExtension:@"m"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSString *rubyScriptPath = [[NSBundle mainBundle] pathForResource:@"CustomRubyScript.rb" ofType:nil];
    NSString *copyScriptPath = [savePath stringByAppendingPathComponent:xcodeProjName];
    
    [[NSFileManager defaultManager] copyItemAtPath:rubyScriptPath toPath:copyScriptPath error:NULL];
//    system([[@"/Users/johnson/.rvm/rubies/ruby-2.2.2/bin/ruby" stringByAppendingFormat:@" %@", copyScriptPath] UTF8String]);
    system([[@"/usr/bin/ruby" stringByAppendingFormat:@" %@", copyScriptPath] UTF8String]);
    [[NSFileManager defaultManager] removeItemAtPath:copyScriptPath error:NULL];
 
    [self saveCurrentData];
    [self showHudForText:@"请到工程中查看已生成的Model" delay:1.f];
}

- (void)hideHud
{
    [self.textFieldHud setHidden:YES];
}

- (void)showHudForText:(NSString *)text delay:(NSTimeInterval)delay;
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
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
