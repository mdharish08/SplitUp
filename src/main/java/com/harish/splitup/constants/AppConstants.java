package com.harish.splitup.constants;

public class AppConstants {

     public enum Gender {
         MALE , FEMALE , NOT_PROVIDED
    }

    public enum GroupType {
         HOME , COUPLE , TRIP , APARTMENT , OTHER
    }

    public enum ExpenseType {
         PAYMENT , EXPENSE
    }

    public enum CommentType {
         SYSTEM , USER
    }

    public enum CurrencyCode {
        USD, EUR, INR, GBP, JPY,
    }

    public enum AccountStatus {
        INVITED, ACTIVE
    }

}
