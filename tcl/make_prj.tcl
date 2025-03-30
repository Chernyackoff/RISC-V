#setting env 
set script_path [ file dirname [ file normalize [ info script ] ] ] 
cd $script_path 
cd ../ 
set CURRENT_DIR [pwd] 
 
puts "script dir: $script_path"  
puts "work dir: $CURRENT_DIR"  
#end setting env 
 
source $script_path/default_values.tcl

# Define IP repository directory
set IP_REPO_DIR "$CURRENT_DIR/ip" 
 
puts "project name: $PROJECT_NAME"  
puts "FPGA part: $FPGA_PART"  
puts "target lang: $TARGET_LANG" 
 
close_project -quiet 

# Create a directory for BD backups if it doesn't exist
set BD_BACKUP_DIR "$CURRENT_DIR/bd_backup"
if { [file exists $BD_BACKUP_DIR] != 1 } {
    file mkdir $BD_BACKUP_DIR
    puts "Created BD backup directory: $BD_BACKUP_DIR"
}

# If project exists, backup BD files before deleting
if { [file exists $PROJECT_DIR] != 0 } {  
    # Find and backup all .bd files from the project
    set bd_files [glob -nocomplain $PROJECT_DIR/*.srcs/sources_1/bd/*/*.bd]
    foreach bd_file $bd_files {
        set bd_filename [file tail $bd_file]
        set bd_design_name [file rootname $bd_filename]
        
        puts "Backing up BD file: $bd_filename"
        file copy -force $bd_file "$BD_BACKUP_DIR/$bd_filename"
    }
    
    # Now delete the project
    file delete -force $PROJECT_NAME 
    puts "Delete old Project" 
} 

# Create new project
create_project $PROJECT_NAME $PROJECT_DIR -part $FPGA_PART 
set_property target_language $TARGET_LANG [current_project] 
set_property simulator_language $SIM_LANG [current_project] 

# Create the IP repository directory if it doesn't exist
if { [file exists $IP_REPO_DIR] != 1 } {
    file mkdir $IP_REPO_DIR
    puts "Created IP repository directory: $IP_REPO_DIR"
}

# Set IP repository paths (both the default from default_values.tcl and our new one)
set_property ip_repo_paths [list $__IP_PATH $IP_REPO_DIR] [current_project] 
 
update_ip_catalog 
 
add_files -fileset constrs_1 -quiet [glob -nocomplain $CNSTR_DIR/*] 
add_files -fileset sources_1 [glob $SRC_DIR/*]  
add_files -fileset sim_1 [glob $SIM_DIR/*]  
set SRC_DIR_PATH "[file normalize "$SRC_DIR"]" 
set SIM_DIR_PATH "[file normalize "$SIM_DIR"]" 
set_property library work [get_files $SRC_DIR_PATH/*]
set_property library work [get_files $SIM_DIR_PATH/*]
 
# Restore backed up BD files if they exist
set bd_backups [glob -nocomplain $BD_BACKUP_DIR/*.bd]
if {[llength $bd_backups] > 0} {
    puts "Restoring backed up BD files to src directory"
    foreach bd_backup $bd_backups {
        set bd_filename [file tail $bd_backup]
        set destination "$SRC_DIR/$bd_filename"
        file copy -force $bd_backup $destination
        puts "Restored: $bd_filename to $destination"
    }
    
    # Import the BD files into the project
    import_files -norecurse [glob -nocomplain $SRC_DIR/*.bd]
    
    # Make sure BD files are kept in sync with their source location
    set bd_files_in_project [get_files -quiet -of_objects [get_filesets sources_1] *.bd]
    foreach bd_file $bd_files_in_project {
        set_property "REGISTERED_WITH_MANAGER" "1" $bd_file
        set_property "SYNTH_CHECKPOINT_MODE" "Hierarchical" $bd_file
    }
}

# Set property to keep BD files editable in place
set_property source_mgmt_mode DisplayOnly [current_project]
 
update_ip_catalog 
 
update_compile_order -quiet -fileset sources_1 
 
set_property -quiet top $TOP_FILE_NAME [get_filesets sources_1] 
 
set_property INCREMENTAL $INCREMENTAL_BUILD [get_filesets sim_1] 
 
update_compile_order -quiet -fileset sources_1 
update_compile_order -quiet -fileset sim_1 
set_property -name {xsim.simulate.runtime} -value {} -objects [get_filesets sim_1]