package com.harish.splitup.entities;

import com.harish.splitup.dto.SplitDetailsDto;
import jakarta.persistence.*;
import lombok.Data;

import java.sql.Timestamp;

@Data
@Entity
@Table(name = "split_details")
public class SplitDetails {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long splitId;

    @ManyToOne
    @JoinColumn(name = "expenseId")
    private Expense expense;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private SplitUser user;

    private double paidShare = 0.0;

    private double owedShare = 0.0;

    private double netBalance = 0.0;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    public SplitDetailsDto toDTO(){
        SplitDetailsDto splitDetailsDto = new SplitDetailsDto();
        splitDetailsDto.setUserId(this.getUser().getId());
        splitDetailsDto.setOwedShare(this.getOwedShare());
        splitDetailsDto.setOwedShare(this.getOwedShare());
        splitDetailsDto.setNetBalance(this.getNetBalance());
        splitDetailsDto.setUser(this.getUser().toDTO());
        return splitDetailsDto;
    }
}
