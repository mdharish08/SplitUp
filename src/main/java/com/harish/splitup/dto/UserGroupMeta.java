package com.harish.splitup.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.sql.Timestamp;
import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserGroupMeta {
    private Long id;
    private String name;
    private String groupType;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private List<GroupMemberMeta> members;
    private String description;

    @Data
    public static class GroupMemberMeta{
        private Long id;
        private String email;
        private String firstName;
        private String lastName;
        private String registrationStatus;
        private BalanceDto balance;
    }
}
