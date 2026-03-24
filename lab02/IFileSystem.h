#pragma once
#include <string>
#include <vector>
#include <memory>

class IFileSystemNode {
public:
    virtual ~IFileSystemNode() = default;

    virtual std::string name() const = 0;
    virtual std::string path() const = 0;
    virtual bool isDirectory() const = 0;
    virtual long long size() const = 0;
    virtual std::string creationDate() const = 0;
    
    virtual std::vector<std::shared_ptr<IFileSystemNode>> children() const = 0;

    virtual bool renameItem(const std::string& newName) = 0;
    virtual bool remove() = 0;
};