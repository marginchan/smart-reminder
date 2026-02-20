require 'xcodeproj'

project_path = 'SmartReminder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target (e.g., SmartReminder)
target = project.targets.first

# The file to add
file_path = 'SmartReminder/Views/GarfieldGameView.swift'

# Find the group "Views"
group = project.main_group.find_subpath(File.dirname(file_path), true)
group.set_source_tree('SOURCE_ROOT')

# Add the file to the group
file_ref = group.new_reference(File.basename(file_path))

# Add the file to the target's source build phase
target.source_build_phase.add_file_reference(file_ref)

project.save
puts "Successfully added #{file_path} to Xcode project target #{target.name}"
