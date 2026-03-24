#import <Foundation/Foundation.h>
#include "FileSystemComposite.h"

FSComponent::FSComponent(const std::string& path) : m_path(path) {
    m_name = [[[NSString stringWithUTF8String:path.c_str()] lastPathComponent] UTF8String];
}

std::string FSComponent::creationDate() const {
    NSError* error = nil;
    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithUTF8String:m_path.c_str()] error:&error];
    if (attrs && attrs[NSFileCreationDate]) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        return [[formatter stringFromDate:attrs[NSFileCreationDate]] UTF8String];
    }
    return "Unknown";
}

bool FSComponent::renameItem(const std::string& newName) {
    NSString* oldPath = [NSString stringWithUTF8String:m_path.c_str()];
    NSString* dir = [oldPath stringByDeletingLastPathComponent];
    NSString* newPath = [dir stringByAppendingPathComponent:[NSString stringWithUTF8String:newName.c_str()]];
    
    NSError* error = nil;
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
    if (success) {
        m_path = [newPath UTF8String];
        m_name = newName;
    }
    return success;
}

bool FSComponent::remove() {
    return [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:m_path.c_str()] error:nil];
}

// --- Файл ---
long long FSFile::size() const {
    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithUTF8String:m_path.c_str()] error:nil];
    return [attrs fileSize];
}

std::vector<std::shared_ptr<IFileSystemNode>> FSFile::children() const {
    return {};
}

// --- Директория ---
long long FSDirectory::size() const {
    NSString *nsPath = [NSString stringWithUTF8String:m_path.c_str()];
    NSURL *url = [NSURL fileURLWithPath:nsPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
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

std::vector<std::shared_ptr<IFileSystemNode>> FSDirectory::children() const {
    std::vector<std::shared_ptr<IFileSystemNode>> list;
    NSString* nsPath = [NSString stringWithUTF8String:m_path.c_str()];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSError* error = nil;
    NSArray* contents = [fm contentsOfDirectoryAtPath:nsPath error:&error];
    if (!contents) return list;

    for (NSString* item in contents) {
        if ([item hasPrefix:@"."]) continue;
        
        NSString* fullPath = [nsPath stringByAppendingPathComponent:item];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir]) {
            std::string cPath = [fullPath UTF8String];
            if (isDir) list.push_back(std::make_shared<FSDirectory>(cPath));
            else list.push_back(std::make_shared<FSFile>(cPath));
        }
    }
    return list;
}