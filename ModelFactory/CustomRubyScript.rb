#拼接路径
#require File::join('/Users', `whoami`.chomp, '/Library/ModelFactory/xcodeproj/xcodeproj.rb')
#require '/Users/johnson/Desktop/xcodeproj/xcodeproj.rb'

# 设置引用头前半部分
# $:<< Xcodeproj.basePath + 'gems/xcodeproj-0.24.2/lib'

# 导入头 "导入事先拷贝到用户library下面的xcodeproj"
basePath = File::join('/Users', `whoami`.chomp, '/Library/ModelFactory/')
require basePath + 'gems/xcodeproj-0.24.2/lib/xcodeproj'
require 'pathname'

# 设置Ruby的默认编码
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# 得到执行脚本文件的路径
scriptPath = Pathname.new(__FILE__).realpath.to_s
# 脚本文件名
scriptName = scriptPath.split('/').last
arrayProjectNameAndModelName = scriptPath.to_s.split('/').last.to_s.split('_')
# 项目名称&Model名称
projectName = arrayProjectNameAndModelName.first.to_s
modelName = arrayProjectNameAndModelName.last.to_s.delete ".rb";

# 项目名称的父文件夹
xcodeprojSuperFolder = '/' + scriptPath.sub(scriptName, '').split('/').last
# 项目可执行文件的路径&引用Model文件的路径
project_xcodeproj_path = scriptPath.sub(scriptName, '').sub(xcodeprojSuperFolder, '') + projectName + '.xcodeproj'
reference_path_h = scriptPath.sub(scriptName, modelName + '.h')
reference_path_m = scriptPath.sub(scriptName, modelName + '.m')

# puts 'scriptPath:' + scriptPath, 'scriptName:' + scriptName
# puts 'projectName:' + projectName, 'modelName:' + modelName
# puts 'xcodeprojSuperFolder:' + xcodeprojSuperFolder
# puts 'project_xcodeproj_path:' + project_xcodeproj_path
# puts 'reference_path_h:' + reference_path_h
# puts 'reference_path_m:' + reference_path_m


# 得到工程文件的xcodeproj
project = Xcodeproj::Project.open(project_xcodeproj_path)
target = project.targets.first

# 创建并添加引用目录
groupName = 'Models'
flag = project.main_group.groups.last.to_s.eql?(groupName)
group = flag ? project.main_group.groups.last : project.main_group.find_subpath(File.join(groupName), true)
# group = project.main_group.find_subpath(File.join('DKNightVersion', 'Pod', 'Classes', 'UIKit'), true)

# 设置引用目录到工程根目录
group.set_source_tree('SOURCE_ROOT')

# 添加文件引用
file_ref_h = group.new_reference(reference_path_h)
file_ref_m = group.new_reference(reference_path_m)
if target.headers_build_phase.files_references.include?(file_ref_h) == false
    target.add_file_references([file_ref_h, file_ref_m])
    project.save
end

# 添加资源文件
# target.add_resources([file_ref_h, file_ref_m])