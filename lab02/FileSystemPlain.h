#pragma once
#include "IFileSystem.h"

// Единый класс для всего. Логика ветвится через if (m_isDir)
class FSPlainNode : public IFileSystemNode {
private:
    std::string m_path;
    std::string m_name;
    bool m_isDir;

public:
    FSPlainNode(const std::string& path);
    
    std::string name() const override { return m_name; }
    std::string path() const override { return m_path; }
    bool isDirectory() const override { return m_isDir; }
    
    long long size() const override;
    std::string creationDate() const override;
    std::vector<std::shared_ptr<IFileSystemNode>> children() const override;
    
    bool renameItem(const std::string& newName) override;
    bool remove() override;
};