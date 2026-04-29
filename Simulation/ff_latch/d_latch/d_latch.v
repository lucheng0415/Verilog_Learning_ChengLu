module d_latch ( input d,
                 input en,
                 input rstn,
                 output reg q);

    always @ (*) begin
        if (!rstn)
            q = 0;
        else if (en)
            q = d;
    end

endmodule
