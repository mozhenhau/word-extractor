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

@property(nonatomic,strong)NSSet* keywordSet;  //词库
@property(nonatomic,strong)NSMutableSet* phraseSet;  //短语库
@property(nonatomic,strong)NSSet* symbolSet;    //需处理的特殊符号
@property(nonatomic,strong)NSSet* tenseSet;    //需处理的时态
@property(nonatomic,strong)NSSet* irregularSet;    //需处理的不规则单词

@property(nonatomic,strong)NSMutableArray* extractArr;   //最终提取的单词
@property(nonatomic,assign)NSTimeInterval useTime;  //提词所用时间
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCondition];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadData];
}

-(void)initCondition{
    _keywordSet = [self loadKeywords];
    //短语库
    _phraseSet = [[NSMutableSet alloc] initWithCapacity:1];
    for (NSString *key in _keywordSet) {
        if ([key containsString:@"..."]) {
            [_phraseSet addObject:key];
        }
    }
    _symbolSet = [NSSet setWithObjects:@"-", nil];
    _tenseSet = [NSSet setWithObjects:@"ed",@"ing",@"s",@"es",@"ies", nil];
    _irregularSet = [NSSet setWithObjects:@"drunk", nil];
    _extractArr = [NSMutableArray arrayWithCapacity:1];
}

-(void)loadData{
    NSString *testString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"540" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    
    _useTime = [NSDate timeIntervalSinceReferenceDate];
    [self addExtractWithString:testString separatedBy:@"\n"];
    _useTime = [NSDate timeIntervalSinceReferenceDate] - _useTime;
    
    _totalCountLabel.text = [NSString stringWithFormat:@"共%d个提词,用时:%f秒",_extractArr.count,_useTime];
    [_tableView reloadData];

}
#pragma mark 提词
/**
 *  加单词到提词列表
 *  1.先提取短句
 *  2.特殊字符处理
 *  3.时态变形处理
 *  4.检验该单词是否在词库,不重复加入
 *
 *  @param text 需要加的单词或语句
 *  @param separatedBy 分割语句方式
 *
 *  @return YES则继续查找该单词,NO则已提取跳过该单词
 */
-(void)addExtractWithString:(NSString*)text separatedBy:(NSString*)separator{
    //分割txt单词
    NSArray *textArr = [text componentsSeparatedByString:separator];
    
    //迭代文本单词列表
    for (NSString *word in textArr) {
        if ([word isEqualToString:@""] || [_extractArr containsObject:word]) {
            continue;
        }
        
        BOOL continueExtract = YES;
        //是句子,先提取短语. 例如as ... as
        if ([word containsString:@" "]) {
            //FIXME: 影响性能
            for (NSString *key in _phraseSet) {
                NSString *regex = [key stringByReplacingCharactersInRange:[key rangeOfString:@"\\s*\\...\\s*" options:NSRegularExpressionSearch] withString:@".*\\w+.*"];
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@".*%@.*",regex]];
                
                //词库匹配到短句且不重复则加入,提词成功
                if ([pred evaluateWithObject:word] && ![_extractArr containsObject:key]) {
                    [_extractArr addObject:key];
                    continue;
                }
            }
            //再查找句子里的单词
            [self addExtractWithString:word separatedBy:@" "];
        }
    
        
        //检验是否有特殊字符,存在则需要递归处理
        for (NSString *symbol in _symbolSet) {
            if ([word rangeOfString:symbol].length > 0) {
                [self addExtractWithString:word separatedBy:symbol];
                continue;
            }
        }
        
        //检验时态变形
        for (NSString* tense in _tenseSet) {
            if ([word hasSuffix:tense]) {
                NSString *originalWord = [word stringByReplacingOccurrencesOfString:tense withString:@""];
                if ([_keywordSet containsObject:originalWord]) {
                    [_extractArr addObject:originalWord];
                    continueExtract = NO;
                    continue;
                }
            }
        }
        
        if (!continueExtract) {
            continue;
        }
        
        //词库有且不重复则加入,提词成功
        if ([_keywordSet containsObject:word]) {
            [_extractArr addObject:word];
        }
    }
    
}



/**
 *  加载词库
 *
 *  @return 返回词库单词列表
 */
-(NSSet*)loadKeywords{
    NSString* fileRoot = [[NSBundle mainBundle] pathForResource:@"word-list" ofType:@"txt"];
    NSString* fileContents = [NSString stringWithContentsOfFile:fileRoot encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray *keywords = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [NSSet setWithArray:keywords];
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
