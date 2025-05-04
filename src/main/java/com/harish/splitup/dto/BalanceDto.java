package com.harish.splitup.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class BalanceDto {

    @JsonProperty(value = "currency_code")
    private String currencyCode;

    private double amount;
}
