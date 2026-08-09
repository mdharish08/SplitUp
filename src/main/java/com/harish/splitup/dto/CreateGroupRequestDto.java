package com.harish.splitup.dto;

import com.harish.splitup.constants.AppConstants;

import java.util.List;

public record CreateGroupRequestDto(
        String name,
        AppConstants.GroupType groupType,
        AppConstants.CurrencyCode currencyCode,
        String description,
        List<GroupMemberRequestDto> members
) {
    public record GroupMemberRequestDto(Long id) {
    }
}
