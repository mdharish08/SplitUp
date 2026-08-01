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

    public static <T> ResponseDto<T> success(T data) {
        ResponseDto<T> dto = new ResponseDto<>();
        dto.setCode(0);
        dto.setMessage("success");
        dto.setData(data);
        return dto;
    }

    public static <T> ResponseDto<T> error(String errorMessage) {
        ResponseDto<T> dto = new ResponseDto<>();
        dto.setCode(1);
        dto.setMessage("failed");
        dto.setError(errorMessage);
        return dto;
    }
}
