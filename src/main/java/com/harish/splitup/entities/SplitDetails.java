package com.harish.splitup.entities;

import com.harish.splitup.dto.SplitDetailsDto;
import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Data;

import java.sql.Timestamp;

@Data
@Entity
@Table(name = "split_details")
public class SplitDetails {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long splitId;

    @ManyToOne
    @JoinColumn(name = "expense_id")
    private Expense expense;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private SplitUser user;

    private BigDecimal paidShare = BigDecimal.ZERO;

    private BigDecimal owedShare = BigDecimal.ZERO;

    private BigDecimal netBalance = BigDecimal.ZERO;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    public SplitDetailsDto toDTO(){
        SplitDetailsDto splitDetailsDto = new SplitDetailsDto();
        splitDetailsDto.setUserId(this.getUser().getId());
        splitDetailsDto.setPaidShare(this.getPaidShare());
        splitDetailsDto.setOwedShare(this.getOwedShare());
        splitDetailsDto.setNetBalance(this.getNetBalance());
        splitDetailsDto.setUser(this.getUser().toDTO());
        return splitDetailsDto;
    }
}
