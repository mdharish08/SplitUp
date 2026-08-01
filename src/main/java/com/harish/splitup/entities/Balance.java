package com.harish.splitup.entities;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.BalanceDto;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.sql.Timestamp;

@Data
@Entity
@Table(name = "balances", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "friend_id", "group_id"})
})
@Builder(setterPrefix = "with")
@NoArgsConstructor
@AllArgsConstructor
@JsonIdentityInfo(generator= ObjectIdGenerators.PropertyGenerator.class, property="balanceId")
public class Balance {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long balanceId;

    @ManyToOne
    @JoinColumn(name = "group_id")
    private Group group;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private SplitUser user;

    @ManyToOne
    @JoinColumn(name = "friend_id", nullable = false)
    private SplitUser friend;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false,length = 4)
    private AppConstants.CurrencyCode currencyCode;

    private BigDecimal amount;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    public BalanceDto balanceDto(){
        BalanceDto dto = new BalanceDto();
        dto.setAmount(this.getAmount());
        dto.setCurrencyCode(this.getCurrencyCode().name());
        return dto;
    }

}
