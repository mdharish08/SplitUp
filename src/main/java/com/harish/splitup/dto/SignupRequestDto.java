package com.harish.splitup.dto;

import lombok.Data;

@Data
public class SignupRequestDto {

    private String firstName;
    private String lastName;
    private String emailId;
    private String password;
}
