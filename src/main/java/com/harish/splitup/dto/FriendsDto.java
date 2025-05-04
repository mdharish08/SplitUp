package com.harish.splitup.dto;

import lombok.Data;

import java.sql.Timestamp;
import java.util.List;

@Data
public class FriendsDto {

    private Long id;
    private String firstName;
    private String lastName;
    private String userName;
    private String registrationStatus;
    private BalanceDto balanceDto;
    private String emailId;
    private List<FriendsGroupDto> groups;
    private Timestamp updatedAt;


    @Data
    public static class FriendsGroupDto {
        private Long groupId;
        private BalanceDto balanceDto;
    }

}


