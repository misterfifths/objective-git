//
//  GTDiffHunk.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffHunk.h"

#import "GTDiffDelta.h"
#import "GTDiffLine.h"

@interface GTDiffHunk ()

@property (nonatomic, assign, readonly) const git_diff_hunk *git_hunk;
@property (nonatomic, strong, readonly) GTDiffDelta *delta;
@property (nonatomic, assign, readonly) NSUInteger hunkIndex;
@property (nonatomic, copy) NSString *header;
@property (nonatomic, strong) NSArray *hunkLines;

@end

@implementation GTDiffHunk

- (instancetype)initWithGitHunk:(const git_diff_hunk *)hunk hunkIndex:(NSUInteger)hunkIndex delta:(GTDiffDelta *)delta {
	self = [super init];
	if (self == nil) return nil;
	
	_delta = delta;
	_git_hunk = hunk;
	_hunkIndex = hunkIndex;

	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ hunkIndex: %ld, header: %@, lineCount: %ld", super.debugDescription, (unsigned long)self.hunkIndex, self.header, (unsigned long)self.lineCount];
}

- (NSString *)header {
	if (_header == nil) {
		_header = [[[NSString alloc] initWithBytes:self.git_hunk->header length:self.git_hunk->header_len encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
	}
	return [_header copy];
}

- (NSUInteger)lineCount {
	return git_patch_num_lines_in_hunk(self.delta.git_patch, self.hunkIndex);
}

- (void)buildLineArrayWithBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSMutableArray *hunkLines = [NSMutableArray arrayWithCapacity:self.lineCount];

	for (NSUInteger idx = 0; idx < self.lineCount; idx ++) {
		const git_diff_line *gitLine;
		int result = git_patch_get_line_in_hunk(&gitLine, self.delta.git_patch, self.hunkIndex, idx);
		// FIXME: Report error ?
		if (result != GIT_OK) continue;

		GTDiffLine *line = [[GTDiffLine alloc] initWithGitLine:gitLine];
		[hunkLines addObject:line];

		if (block == nil) continue;

		BOOL stop = NO;
		block(line, &stop);
		if (stop) return;
	}
	self.hunkLines = hunkLines;
}

- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSParameterAssert(block != nil);

	if (self.hunkLines == nil) {
		[self buildLineArrayWithBlock:block];
		return;
	}
	[self.hunkLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		block(obj, stop);
	}];
}

@end
