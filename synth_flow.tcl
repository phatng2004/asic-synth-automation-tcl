# =======================================================================
# Project: Automated ASIC Multi-Block Logic Synthesis & Profiler
# Language: Tcl (executed inside Yosys)
# =======================================================================

# 1. Cấu hình danh sách các block cần tổng hợp (Chương 4, 6)
set design_list {
    {alu         rtl/alu.v}
    {fifo_buffer rtl/fifo_buffer.v}
}

# Associative Array lưu trữ kết quả trích xuất (Chương 4)
array set summary_metrics {}

# 2. Procedure tổng hợp cho từng module (Chương 8, 9, 11)
proc synthesize_module {top_module source_file} {
    puts "\n========================================================"
    puts "--> STARTING SYNTHESIS FOR MODULE: $top_module"
    puts "========================================================"

    # Kiểm tra file nguồn tồn tại (Chương 11)
    if {![file exists $source_file]} {
        error "Source file '$source_file' not found!"
    }

    # Reset môi trường thiết kế trước khi đọc file mới
    yosys design -reset

    # Đọc và chạy các bước tổng hợp logic qua wrapper 'yosys'
    yosys read_verilog $source_file
    yosys hierarchy -check -top $top_module
    yosys proc
    yosys opt
    yosys fsm
    yosys opt
    yosys memory
    yosys opt
    yosys techmap
    yosys opt

    # Dùng lệnh tee của Yosys để xuất kết quả stat ra file tạm
    set tmp_stat_file "temp_${top_module}_stat.txt"
    yosys tee -q -o $tmp_stat_file stat

    # Đọc nội dung file log tạm bằng file I/O (Chương 11)
    set fp [open $tmp_stat_file "r"]
    set stat_output [read $fp]
    close $fp

    # Dọn dẹp file tạm
    file delete -force $tmp_stat_file

    return $stat_output
}

# 3. Procedure bóc tách thông số bằng Regular Expression (Chương 10)
proc parse_statistics {top_module stat_text array_name} {
    upvar $array_name metrics

    set num_wires 0
    set num_cells 0
    set num_dff 0

    # Lọc số lượng wires
    if {[regexp -nocase {Number of wires:\s+([0-9]+)} $stat_text -> w_count]} {
        set num_wires $w_count
    }

    # Lọc tổng số cells/gates
    if {[regexp -nocase {Number of cells:\s+([0-9]+)} $stat_text -> c_count]} {
        set num_cells $c_count
    }

    # Lọc mọi biến thể của Flip-Flop: $dff, $adff, $dffe, $adffe, $_DFF_...
    foreach line [split $stat_text "\n"] {
        if {[regexp -nocase {^\s*(\$_DFF[^\s]*|\$[a-z]*dff[^\s]*)\s+([0-9]+)} $line -> cell_type dff_count]} {
            set num_dff [expr {$num_dff + $dff_count}]
        }
    }

    # Lưu kết quả vào mảng liên kết (Chương 4)
    set metrics($top_module,wires) $num_wires
    set metrics($top_module,cells) $num_cells
    set metrics($top_module,dff)   $num_dff
}





# 4. Procedure ghi file báo cáo tóm tắt định dạng bảng (Chương 10, 11)
proc export_summary_report {output_filename array_name designs} {
    upvar $array_name metrics

    set fp [open $output_filename "w"]
    
    # Căn lề các cột bằng format (Chương 10)
    set header [format "| %-15s | %-12s | %-12s | %-12s |" "Module Name" "Wire Count" "Cell Count" "DFF Count"]
    set sep    "+-----------------+--------------+--------------+--------------+"

    puts $fp $sep
    puts $fp $header
    puts $fp $sep

    foreach item $designs {
        set top [lindex $item 0]
        set row [format "| %-15s | %-12s | %-12s | %-12s |" \
                    $top \
                    $metrics($top,wires) \
                    $metrics($top,cells) \
                    $metrics($top,dff)]
        puts $fp $row
    }
    puts $fp $sep
    close $fp

    puts "\n\[SUCCESS\] Summary report written to: $output_filename"
}

# =======================================================================
# Luồng thực thi chính (Chương 7, 9)
# =======================================================================
foreach design $design_list {
    set top_name [lindex $design 0]
    set src_path [lindex $design 1]

    # Bắt lỗi với catch để nếu 1 block lỗi thì các block khác vẫn chạy tiếp (Chương 9)
    set status [catch {synthesize_module $top_name $src_path} result_or_err]

    if {$status == 0} {
        parse_statistics $top_name $result_or_err summary_metrics
    } else {
        puts stderr "\[ERROR\] Synthesis failed for $top_name: $result_or_err"
        set summary_metrics($top_name,wires) "ERROR"
        set summary_metrics($top_name,cells) "ERROR"
        set summary_metrics($top_name,dff)   "ERROR"
    }
}

# Xuất bảng báo cáo tổng kết ra file
export_summary_report "synth_summary.rpt" summary_metrics $design_list

