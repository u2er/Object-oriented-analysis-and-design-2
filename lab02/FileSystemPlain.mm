#import <Foundation/Foundation.h>
#include "FileSystemPlain.h"

FSPlainNode::FSPlainNode(const std::string& path) : m_path(path) {
    NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
    m_name = [[nsPath lastPathComponent] UTF8String];
    
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:nsPath isDirectory:&isDir];
    m_isDir = isDir;
}

long long FSPlainNode::size() const {
    NSString *nsPath = [NSString stringWithUTF8String:m_path.c_str()];
    NSFileManager *fm = [NSFileManager defaultManager];

    if (!m_isDir) {
        NSDictionary* attrs = [fm attributesOfItemAtPath:nsPath error:nil];
        return [attrs fileSize];
    }

    NSURL *url = [NSURL fileURLWithPath:nsPath];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:url
                                 includingPropertiesForKeys:@[NSURLFileSizeKey]
                                                    options:0
                                               errorHandler:nil];
    long long totalSize = 0;
    for (NSURL *fileURL in enumerator) {
        NSNumber *fileSize;
        [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        totalSize += [fileSize longLongValue];
    }
    return totalSize;
}

std::string FSPlainNode::creationDate() const {
    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithUTF8String:m_path.c_str()] error:nil];
    if (attrs && attrs[NSFileCreationDate]) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        return [[formatter stringFromDate:attrs[NSFileCreationDate]] UTF8String];
    }
    return "Unknown";
}

std::vector<std::shared_ptr<IFileSystemNode>> FSPlainNode::children() const {
    std::vector<std::shared_ptr<IFileSystemNode>> list;
    if (!m_isDir) return list; // Без паттерна приходится делать проверку вручную
    
    NSString* nsPath = [NSString stringWithUTF8String:m_path.c_str()];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:nsPath error:nil];
    
    for (NSString* item in contents) {
        if ([item hasPrefix:@"."]) continue;
        list.push_back(std::make_shared<FSPlainNode>([[nsPath stringByAppendingPathComponent:item] UTF8String]));
    }
    return list;
}

bool FSPlainNode::renameItem(const std::string& newName) {
    NSString* oldP = [NSString stringWithUTF8String:m_path.c_str()];
    NSString* newP = [[oldP stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithUTF8String:newName.c_str()]];
    if ([[NSFileManager defaultManager] moveItemAtPath:oldP toPath:newP error:nil]) {
        m_path = [newP UTF8String];
        m_name = newName;
        return true;
    }
    return false;
}

bool FSPlainNode::remove() {
    return [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:m_path.c_str()] error:nil];
}