package com.harish.splitup.dto;

import lombok.Data;

@Data
public class SplitDetailsDto {

    private Long userId;

    private UserDto user;

    private Double paidShare = 0.0;

    private Double owedShare = 0.0;

    private Double netBalance = 0.0;
}
