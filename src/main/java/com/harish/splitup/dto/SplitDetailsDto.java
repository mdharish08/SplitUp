package com.harish.splitup.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class SplitDetailsDto {

    private Long userId;

    private UserDto user;

    private BigDecimal paidShare = BigDecimal.ZERO;

    private BigDecimal owedShare = BigDecimal.ZERO;

    private BigDecimal netBalance = BigDecimal.ZERO;
}
