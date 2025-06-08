package com.harish.splitup.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ResponseDto<T> {
    private String message;
    private T data;
    private int code;
    private String error;
}
