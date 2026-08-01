package com.harish.splitup.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class BalanceDto {

    @JsonProperty(value = "currency_code")
    private String currencyCode;

    private BigDecimal amount;
}
