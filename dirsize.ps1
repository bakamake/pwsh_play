using namespace System;
using namespace System.IO;
using namespace System.Linq;

public class DirectorySizeCalculator
{
    public static long GetDirectorySize(string path)
    {
        long totalSize = 0;

        // 配置枚举选项以实现最高性能
        $options = new EnumerationOptions
        {
            RecurseSubdirectories = true,     // 递归
            IgnoreInaccessible = true,        // 跳过权限不足的目录
            AttributesToSkip = FileAttributes.ReparsePoint, // 关键：跳过符号链接，防止死循环
            ReturnSpecialDirectories = false,
            BufferSize = 8192                 // 增大缓冲区减少系统调用次数
        };

        $dirInfo = new DirectoryInfo(path);

        // 使用 EnumerateFiles 而不是 GetFiles
        // 这样它是基于流式处理的，内存中只会保留当前处理的文件对象
        foreach ($file in dirInfo.EnumerateFiles("*", options))
        {
            totalSize += file.Length;
        }

        return totalSize;
    }
}
