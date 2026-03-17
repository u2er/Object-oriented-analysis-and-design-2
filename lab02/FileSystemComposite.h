#pragma once
#include "IFileSystem.h"

// Базовый класс компонента
class FSComponent : public IFileSystemNode {
protected:
    std::string m_path;
    std::string m_name;
public:
    FSComponent(const std::string& path);
    std::string name() const override { return m_name; }
    std::string path() const override { return m_path; }
    std::string creationDate() const override;
    bool renameItem(const std::string& newName) override;
    bool remove() override;
};

// Лист (Файл)
class FSFile : public FSComponent {
public:
    FSFile(const std::string& path) : FSComponent(path) {}
    bool isDirectory() const override { return false; }
    long long size() const override;
    std::vector<std::shared_ptr<IFileSystemNode>> children() const override;
};

// Композит (Директория)
class FSDirectory : public FSComponent {
public:
    FSDirectory(const std::string& path) : FSComponent(path) {}
    bool isDirectory() const override { return true; }
    long long size() const override; // Рекурсивный (или поверхностный) размер
    std::vector<std::shared_ptr<IFileSystemNode>> children() const override;
};