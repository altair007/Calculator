//
//  Calculator.m
//  Calculator
//
//  Created by   颜风 on 14-5-25.
//  Copyright (c) 2014年 Shadow. All rights reserved.
//

#import "Calculator.h"

@implementation Calculator

#pragma mark - 类方法
+ (CGFloat) calculate: (NSString *) expr
{
    // 清洁字符串
    expr = [self cleanExpr:expr];
    if (expr == nil) {
        NSException * error = [[NSException alloc] initWithName:@"错误" reason:@"不合法的数学表达式" userInfo:nil];
        @throw error;
    }
    
    // 中缀转后缀.
    NSString * rpn = [self trans: expr];
    
    // 计算并返回表达式的值.
    CGFloat result = [self calculateWithRpn:rpn];
    return result;
}

// FIXME: 无法处理第一个数为正数或负数的情况.
+ (NSString *) trans: (NSString *) expr
{
    // 使用两个对象模拟栈:一个用于临时存储运算符,一个用于用于存储最终的结果.
    NSMutableString * resultStack;
    resultStack = [[NSMutableString alloc] initWithCapacity:42]; //!< 用于存储转换结果.
    
    NSMutableString * tempStack; //!< 临时存储运算符的栈,使用字符串对象更方便些.
    tempStack = [[NSMutableString alloc] initWithCapacity:42]; //!< 用于临时存储运算符.
    
    // 对正负数的支持策略:如果前一个字符是操作符'(',则先往结果栈压入一个0
    BOOL isLeftBracketLast = NO; //!< 上一个字符是否是'('.
    
    // 处理第一个数是正数或负数的情况,即第一个符号不是数字,而是'+'或'-',处理策略:-1+2  => -()
    
    // 逆波兰算法的核心
    for (NSInteger i = 0; i < expr.length; i++) {
        unichar ch =  [expr characterAtIndex: i];
        
        switch(ch)
        {
            case '(':
                // 把'('压入临时存放操作符的栈.
                [tempStack appendString:[[NSString alloc] initWithFormat: @"%c", ch]];
                break;
            case ')':
                // 把临时栈中的'('之上的所有字符取出,并舍弃'('
                for (;;) {
                    // 防止越界错误
                    if (tempStack.length == 0) {
                        break;
                    }
                    
                    // 获取临时栈栈顶字符
                    unichar topCh = [tempStack characterAtIndex:tempStack.length - 1];
                    
                    // 删除栈顶字符
                    [tempStack deleteCharactersInRange:NSMakeRange(tempStack.length - 1, 1)];
                    
                    // 如果是栈顶元素是'(',舍弃'(',同时结束循环.
                    if (topCh == '(') {
                        break;
                    }
                    
                    // 把操作符放到存储结果的栈.
                    [resultStack appendString:[[NSString alloc] initWithFormat: @"%c", topCh]];
                }
                break;
            case '+':
            case '-':
                // 用于支持正负数:如果前一个字符是操作符'(',则先往结果栈压入一个0
                if (isLeftBracketLast) {
                    [resultStack appendString:@"0 "];
                }
                
                for (; ; ) {
                    // 防止临时栈越界错误
                    if (tempStack.length == 0) {
                        // 已经到栈底,可以把'+'或'-'操作符 放入临时栈了.
                        [tempStack appendString:[[NSString alloc] initWithFormat: @"%c", ch]];
                        
                        break;
                    }
                    
                    // 获取临时栈栈顶字符
                    unichar topCh = [tempStack characterAtIndex: tempStack.length - 1];
                    
                    // 比较临时栈栈顶字符与新字符的优先级:只有新字符比栈顶运算符优先级小时,才可以入临时栈.'('除外,可认为它优先级最低.
                    if (topCh == '(') { // 此时也可以入临时栈
                        [tempStack appendString:[[NSString alloc] initWithFormat: @"%c", ch]];
                        
                        break;
                    }
                    
                    // 把临时栈栈顶字符取出放到结果栈.
                    [tempStack deleteCharactersInRange:NSMakeRange(tempStack.length - 1, 1)];
                    [resultStack appendString:[[NSString alloc] initWithFormat: @"%c", topCh]];
                }
                
                break;
            case '*':
            case '/':
                for (; ; ) {
                    // 防止临时栈越界错误
                    if (tempStack.length == 0) {
                        // 已经到栈底,可以把'*'或'/'操作符 放入临时栈了.
                        [tempStack appendString:[[NSString alloc] initWithFormat: @"%c", ch]];
                        
                        break;
                    }
                    
                    // 获取临时栈栈顶字符
                    unichar topCh = [tempStack characterAtIndex: tempStack.length - 1];
                    
                    // 比较临时栈栈顶字符与新字符的优先级:只有新字符比栈顶运算符优先级小时,才可以入临时栈.'('除外,可认为它优先级最低.
                    if (topCh != '*' && topCh != '/') { // 此时也可以入临时栈
                        [tempStack appendString:[[NSString alloc] initWithFormat: @"%c", ch]];
                        
                        break;
                    }
                    
                    // 把临时栈栈顶字符取出放到结果栈.
                    [tempStack deleteCharactersInRange:NSMakeRange(tempStack.length - 1, 1)];
                    [resultStack appendString:[[NSString alloc] initWithFormat: @"%c", topCh]];
                }
                
                break;
            default:// 处理数字和小数点:一次性录入后续所有的数字或者小数点,直到遇到操作符,然后用空白分隔.
                for (; i < expr.length; i ++) {
                    // 将字符转换为对象.
                    NSString * tempStr = [expr substringWithRange:NSMakeRange(i, 1)];
                    
                    // 判断字符是有效的数字或者小数点.
                    NSPredicate * predicate =  [NSPredicate predicateWithFormat:@"self MATCHES '^[[0-9][.]]+$'"];
                    BOOL isNum = [predicate evaluateWithObject:tempStr];
                   
                    if (isNum == NO) {// 不是数字,终止循环
                        i --; // 读取了一个字符但没有处理,所以后退一次,保证最外层循环逻辑的正确性.
                        break;
                    }
                    
                    // 是数字或者小数点,直接添加到结果栈.
                    [resultStack appendString:tempStr];
                }
                
                // 用空格分隔数字
                [resultStack appendString:@" "];
                
                break;
        }
        // 此字符是否是'('
        isLeftBracketLast =  NO;
        
        if (ch == '(') {
            isLeftBracketLast = YES;
        }
    }
    
    // 将临时栈中的所有操作符,依次从栈顶取出,放入结果栈.
    for (NSInteger i = tempStack.length - 1; i  >= 0; i --) {
        NSString * tempStr = [tempStack substringWithRange: NSMakeRange(i, 1)];
        [resultStack appendString:tempStr];
    }
    
    // 由于只是模拟栈的行为,我们实际上是把字符添加了用来模拟栈的字符串对象的后面,所以不需要逆序操作了.
    
    // 返回需要的数据类型的结果.
    
    NSString * returnResult = [[NSString alloc] initWithString:resultStack];
    
    return returnResult;
}

+ (CGFloat) calculateWithRpn:(NSString *) rpn
{
    NSMutableArray * resultStack;
    resultStack = [[NSMutableArray alloc] initWithCapacity: 42];
    
    for (NSUInteger i = 0; i < rpn.length; i ++) {
        NSString * curStr = [rpn substringWithRange:NSMakeRange(i, 1)]; //!< 当前字符
        
        // 数字,直接压入栈
        NSPredicate * predicate =  [NSPredicate predicateWithFormat:@"self MATCHES '^[0-9]+$'"];
        BOOL isNum = [predicate evaluateWithObject:curStr];
        
        if (isNum == YES) {
            NSMutableString * numberStr = [[NSMutableString alloc] initWithCapacity:42];
            for (; i < rpn.length; i ++) {
                curStr = [rpn substringWithRange:NSMakeRange(i, 1)];
                if ([curStr isEqualToString:@" "]) {
                    break;
                }
                
                [numberStr appendString:curStr];
            }
            [resultStack addObject:numberStr];
            continue;
        }
        
        // 不是数字,此时栈中至少应该有两个元素.
        if (resultStack.count < 2) {// 不足两个元素,可以直接抛出异常!
            NSException * error = [[NSException alloc] initWithName:@"错误" reason:@"不合法的数学表达式" userInfo:nil];
            @throw error;
        }
        
        // 将栈顶两个数字出栈,进行运算.
        CGFloat topNumber = 0.0;//!< 栈顶数字
        NSNumber * topNumberOriginal = [resultStack objectAtIndex:resultStack.count - 1];
        [resultStack removeObject:topNumberOriginal];
        topNumber = [topNumberOriginal doubleValue];
        
        CGFloat secondNum = 0.0;//!< 栈顶下面下面的数字
        NSNumber * secondStrOrigina = [resultStack objectAtIndex:resultStack.count - 1];
        [resultStack removeObject:secondStrOrigina];
        secondNum = [secondStrOrigina doubleValue];
        
        CGFloat resultTemp = 0.0; //!< 存储计算结果
        
        // 加法
        if ([curStr isEqualToString:@"+"]){
            resultTemp = secondNum + topNumber;
        }
        
        // 减法
        if ([curStr isEqualToString:@"-"]){
            resultTemp = secondNum - topNumber;
        }
        
        // 乘法
        if ([curStr isEqualToString:@"*"]){
            resultTemp = secondNum * topNumber;
        }
        
        // 除法
        if ([curStr isEqualToString:@"/"]){
            if (topNumber == 0) {
                NSException * error = [[NSException alloc] initWithName:@"错误" reason:@"用0作除数" userInfo:nil];
                @throw error;
            }
            
            resultTemp = secondNum / topNumber;
        }
        
        // 将结果压入栈
        [resultStack addObject:[NSNumber numberWithDouble:resultTemp]];
    }
    
    // 最终栈顶只应该有一个元素.
    if (resultStack.count > 1) {
        NSException * error = [[NSException alloc] initWithName:@"错误" reason:@"不合法的数学表达式" userInfo:nil];
        @throw error;
    }
    
    CGFloat result;
    result = [resultStack[0] doubleValue];
    return result;
}

+ (NSString *) cleanExpr: (NSString *)expr
{
    // 是否含有非法字符
    NSPredicate * predicate = [NSPredicate  predicateWithFormat: @"self MATCHES '^[[0-9][+][-][*][/][.][ ][(][)][×][÷]]+$'"];
    BOOL isLegal = [predicate evaluateWithObject:expr];
    if (isLegal == NO) {// 含有非法字符,直接返回nil.
        return nil;
    }
    
    // 处理空白
    NSMutableString * temp;
    temp = [[NSMutableString alloc] initWithString:expr];
    [temp replaceOccurrencesOfString:@"[ ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, temp.length)];
    
    //把× ÷转换为 * /
    [temp replaceOccurrencesOfString:@"[×]" withString:@"*" options:NSRegularExpressionSearch range:NSMakeRange(0, temp.length)];
    [temp replaceOccurrencesOfString:@"[÷]" withString:@"/" options:NSRegularExpressionSearch range:NSMakeRange(0, temp.length)];
    
    // 返回结果
    NSString * result;
    result = [[NSString alloc] initWithString:temp];
    
    return result;
}
@end
