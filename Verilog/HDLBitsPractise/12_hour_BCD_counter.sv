module top_module(
    input      clk,
    input      reset,
    input      ena,
    output reg pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);
    // 进位使能
    wire ena_min  = ena  && (ss == 8'h59);
    wire ena_hour = ena_min && (mm == 8'h59);
    wire ena_pm   = ena_hour && (hh == 8'h11); // 11->12 时 PM 翻转

    // 秒 (00-59 BCD)
    always @(posedge clk) begin
        if (reset)
            ss <= 8'h00;
        else if (ena) begin
            if (ss == 8'h59)
                ss <= 8'h00;
            else if (ss[3:0] == 4'd9) begin
                ss[3:0] <= 4'd0;
                ss[7:4] <= ss[7:4] + 1;
            end else
                ss[3:0] <= ss[3:0] + 1;
        end
    end

    // 分 (00-59 BCD)
    always @(posedge clk) begin
        if (reset)
            mm <= 8'h00;
        else if (ena_min) begin
            if (mm == 8'h59)
                mm <= 8'h00;
            else if (mm[3:0] == 4'd9) begin
                mm[3:0] <= 4'd0;
                mm[7:4] <= mm[7:4] + 1;
            end else
                mm[3:0] <= mm[3:0] + 1;
        end
    end

    // 时 (01-12 BCD，12之后回到01)
    always @(posedge clk) begin
        if (reset)
            hh <= 8'h12;
        else if (ena_hour) begin
            if (hh == 8'h12)
                hh <= 8'h01;        // 12 → 01
            else if (hh[3:0] == 4'd9) begin
                hh[3:0] <= 4'd0;
                hh[7:4] <= hh[7:4] + 1;
            end else
                hh[3:0] <= hh[3:0] + 1;
        end
    end

    // AM/PM：每次 11→12 翻转一次
    always @(posedge clk) begin
        if (reset)
            pm <= 1'b0;         // reset 到 AM
        else if (ena_pm)
            pm <= ~pm;
    end

endmodule