package com.harish.splitup.dto;

import com.harish.splitup.constants.AppConstants;

import java.sql.Timestamp;
import java.util.List;

public record GroupMetaResponseDto(
        Long id,
        String name,
        AppConstants.GroupType groupType,
        AppConstants.CurrencyCode currencyCode,
        String description,
        Timestamp createdAt,
        Timestamp updatedAt,
        List<GroupMemberResponseDto> members
) {
    public record GroupMemberResponseDto(
            Long id,
            String email,
            String firstName,
            String lastName,
            String registrationStatus,
            BalanceDto balance
    ) {
    }
}
