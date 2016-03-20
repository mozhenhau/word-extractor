//
//  ViewController.m
//  TestWord
//
//  Created by 莫振华 on 16/3/19.
//  Copyright © 2016年 莫振华. All rights reserved.
//

#include <stdio.h>
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *totalCountLabel;

@property(nonatomic,strong)NSArray* keywordArr;  //词库
@property(nonatomic,strong)NSArray* symbolArr;    //需处理的特殊符号
@property(nonatomic,strong)NSArray* tenseArr;    //需处理的时态
@property(nonatomic,strong)NSArray* irregularArr;    //需处理的不规则单词

@property(nonatomic,strong)NSMutableArray* extractArr;   //最终提取的单词
@property(nonatomic,assign)NSTimeInterval useTime;  //提词所用时间
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCondition];
    
    NSString *testString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];

    _useTime = [NSDate timeIntervalSinceReferenceDate];
    [self addExtractWithString:testString separatedBy:[NSCharacterSet newlineCharacterSet]];
    _useTime = [NSDate timeIntervalSinceReferenceDate] - _useTime;
    
    _totalCountLabel.text = [NSString stringWithFormat:@"共%d个提词,用时:%f秒",_extractArr.count,_useTime];
    [_tableView reloadData];
}


-(void)initCondition{
    _keywordArr = [self loadKeyword];
    _symbolArr = @[@"-"];
    _tenseArr = @[@"ed",@"ing",@"s",@"es",@"ies"];
    _irregularArr = @[@"drunk"];
    _extractArr = [NSMutableArray arrayWithCapacity:1];
}

#pragma mark 提词
/**
 *  加单词到提词列表
 *  检验该单词是否在词库
 *  不重复加入
 *  特殊字符处理
 *
 *  @param word 需要加的单词
 *
 *  @return YES则继续查找该单词,NO则跳过该单词
 */
-(BOOL)addExtractWithString:(NSString*)text separatedBy:(NSCharacterSet*)separator{
    //分割txt单词
    NSArray *textArr = [text componentsSeparatedByCharactersInSet:separator];
    
    //迭代文本单词列表
    for (NSString *word in textArr) {
        //检验是否空字符串
        if ([word isEqualToString:@""]) {
            continue;
        }
        
        BOOL continueAdd = YES;
        //检验是否有特殊字符,存在则需要递归处理
        for (NSString *symbol in _symbolArr) {
            if ([word rangeOfString:symbol].length > 0 && ![self addExtractWithString:word separatedBy:[NSCharacterSet characterSetWithCharactersInString:symbol]]) {
                continueAdd = NO;
                continue;
            }
        }
        
        //检验时态变形
        for (NSString* tense in _tenseArr) {
            if ([word hasSuffix:tense] && ![self addExtractWithString:word separatedBy:[NSCharacterSet characterSetWithCharactersInString:tense]]) {
                continueAdd = NO;
                continue;
            }
        }
    
        //还是句子,先提取短语
        if ([word containsString:@" "]) {
            continueAdd = NO;
            NSString *key = @"as ... as";
            NSString * regex        = [key stringByReplacingCharactersInRange:[key rangeOfString:@"\\s*\\...\\s*" options:NSRegularExpressionSearch] withString:@".*\\w+.*"];
            NSPredicate * pred      = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
            
            if ([pred evaluateWithObject:word] && ![_extractArr containsObject:key]) {
                [_extractArr addObject:key];
            }
            [self addExtractWithString:word separatedBy:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        
        //如果时态或不规则已提词则不需要再加入
        if (!continueAdd) {
            continue;
        }
            
        //词库有且不重复则加入,提词成功
        if ([_keywordArr containsObject:word] && ![_extractArr containsObject:word]) {
            [_extractArr addObject:word];
            
            //如果是时态变形，则不继续查找
            if ([_tenseArr containsObject:separator]) {
                return NO;
            }
        }
    }
    
    return YES;
}



/**
 *  加载词库
 *
 *  @return 返回词库单词列表
 */
-(NSArray*)loadKeyword{
    NSString* fileRoot = [[NSBundle mainBundle] pathForResource:@"word-list" ofType:@"txt"];
    NSString* fileContents = [NSString stringWithContentsOfFile:fileRoot encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray *keywords = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return keywords;
}


#pragma mark tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _extractArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"word";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",indexPath.row+1,_extractArr[indexPath.row]];
    return cell;
}

@end
