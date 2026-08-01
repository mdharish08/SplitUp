
package com.harish.splitup.entities;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.harish.splitup.constants.AppConstants;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Timestamp;
import java.util.List;

@Data
@Entity
@Table(name = "groups")
@Builder(setterPrefix = "with")
@NoArgsConstructor
@AllArgsConstructor
@JsonIdentityInfo(generator= ObjectIdGenerators.PropertyGenerator.class, property="groupId")
public class Group {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long groupId;

    private String groupName;

    private String groupDescription;

    @Enumerated(EnumType.STRING)
    private AppConstants.GroupType groupType;

    @Enumerated(EnumType.STRING)
    private AppConstants.CurrencyCode currencyCode;

    private long avatar;

    private long createdBy;

    private Long deletedBy;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    private boolean trashed;

    @OneToMany(mappedBy = "group")
    List<Expense> expenses;

    @Override
    public int hashCode(){
        return java.util.Objects.hash(this.groupId,this.groupName);
    }

    @Override
    public boolean equals(Object obj){
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        Group grp = (Group) obj;
        return this.getGroupId() == grp.getGroupId();
    }
}
