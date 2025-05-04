package com.harish.splitup.entities;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.BalanceDto;
import jakarta.persistence.*;
import lombok.Builder;
import lombok.Data;

import java.sql.Timestamp;

@Data
@Entity
@Table(name = "friends")
@Builder(setterPrefix = "with")
@JsonIdentityInfo(generator= ObjectIdGenerators.PropertyGenerator.class, property="balanceId")
public class Balance {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long balanceId;

    @OneToOne
    @JoinColumn(name = "group_id")
    private Group group;

    @OneToOne
    @JoinColumn(name = "user_id")
    private SplitUser user;

    @OneToOne
    @JoinColumn(name = "friend_id")
    private SplitUser friend;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false,length = 4)
    private AppConstants.CurrencyCode currencyCode;

    private double amount;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    public BalanceDto balanceDto(){
        BalanceDto dto = new BalanceDto();
        dto.setAmount(this.getAmount());
        dto.setCurrencyCode(this.getCurrencyCode().name());
        return dto;
    }

}
