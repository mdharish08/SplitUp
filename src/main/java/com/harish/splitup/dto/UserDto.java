package com.harish.splitup.dto;

import lombok.Data;

import java.sql.Timestamp;

@Data
public class UserDto {

    private Long id;
    private String firstName;
    private String lastName;
    private String userName;
    private String registrationStatus;
    private String emailId;
    private Timestamp updatedAt;
}
