package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.CreateGroupRequestDto;
import com.harish.splitup.dto.GroupMetaResponseDto;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.GroupMapping;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.GroupMappingRepository;
import com.harish.splitup.repositories.GroupRepository;
import com.harish.splitup.repositories.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class GroupServiceTest {

    @Mock private GroupRepository groupRepository;
    @Mock private UserRepository userRepository;
    @Mock private GroupMappingRepository groupMappingRepository;
    @Mock private BalanceRepository balanceRepository;

    @InjectMocks
    private GroupService groupService;

    private SplitUser creator;
    private SplitUser member1;
    private SplitUser member2;

    @BeforeEach
    void setUp() {
        creator = SplitUser.builder()
                .withId(1L).withFirstName("Alice").withLastName("Smith")
                .withEmailId("alice@example.com").withUserPassWord("encoded").build();

        member1 = SplitUser.builder()
                .withId(2L).withFirstName("Bob").withLastName("Jones")
                .withEmailId("bob@example.com").withUserPassWord("encoded").build();

        member2 = SplitUser.builder()
                .withId(3L).withFirstName("Carol").withLastName("White")
                .withEmailId("carol@example.com").withUserPassWord("encoded").build();
    }

    private CreateGroupRequestDto buildGroupRequest(String name, AppConstants.GroupType groupType,
                                                    AppConstants.CurrencyCode currencyCode, List<Long> memberIds) {
        List<CreateGroupRequestDto.GroupMemberRequestDto> members = memberIds.stream()
                .map(CreateGroupRequestDto.GroupMemberRequestDto::new)
                .toList();
        return new CreateGroupRequestDto(name, groupType, currencyCode, "Test group", members);
    }

    // ── createGroup ───────────────────────────────────────────────────────────

    @Test
    void createGroup_happyPath_savesGroupMappingsAndBalances() {
        // given
        CreateGroupRequestDto req = buildGroupRequest("Weekend Trip", AppConstants.GroupType.TRIP, AppConstants.CurrencyCode.USD,
                List.of(1L, 2L, 3L));

        given(userRepository.findAllById(anyIterable()))
                .willReturn(List.of(creator, member1, member2));

        // when
        GroupMetaResponseDto result = groupService.createGroup(1L, req);

        // then
        then(groupRepository).should(times(1)).save(any(Group.class));
        then(groupMappingRepository).should(times(1)).saveAll(anyList());
        then(balanceRepository).should(times(1)).saveAll(anyList());
        assertThat(result.name()).isEqualTo("Weekend Trip");
        assertThat(result.members()).hasSize(3);
    }

    @Test
    void createGroup_missingName_throwsIllegalArgument() {
        CreateGroupRequestDto req = buildGroupRequest("", AppConstants.GroupType.TRIP, AppConstants.CurrencyCode.USD, List.of(1L, 2L));

        assertThatThrownBy(() -> groupService.createGroup(1L, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Group name is required");
    }

    @Test
    void createGroup_emptyMembers_throwsIllegalArgument() {
        CreateGroupRequestDto req = buildGroupRequest("My Group", AppConstants.GroupType.HOME, AppConstants.CurrencyCode.USD, List.of());

        assertThatThrownBy(() -> groupService.createGroup(1L, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("At least one member is required");
    }

    @Test
    void createGroup_missingGroupType_throwsIllegalArgument() {
        CreateGroupRequestDto req = new CreateGroupRequestDto(
                "My Group",
                null,
                AppConstants.CurrencyCode.USD,
                "Test group",
                List.of(new CreateGroupRequestDto.GroupMemberRequestDto(1L))
        );

        assertThatThrownBy(() -> groupService.createGroup(1L, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Group type is required");
    }

    @Test
    void createGroup_memberNotFound_throwsIllegalArgument() {
        // given – only 1 of the 2 requested members is found
        CreateGroupRequestDto req = buildGroupRequest("My Group", AppConstants.GroupType.HOME, AppConstants.CurrencyCode.USD, List.of(2L, 99L));
        given(userRepository.findAllById(anyIterable())).willReturn(List.of(creator, member1)); // one missing

        assertThatThrownBy(() -> groupService.createGroup(1L, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("One or more members not found");
    }

    @Test
    @SuppressWarnings("unchecked")
    void createGroup_createsNxNBalanceRecords() {
        // given – 3 members → 3*(3-1) = 6 balance rows
        CreateGroupRequestDto req = buildGroupRequest("Team", AppConstants.GroupType.OTHER, AppConstants.CurrencyCode.USD, List.of(1L, 2L, 3L));
        given(userRepository.findAllById(anyIterable()))
                .willReturn(List.of(creator, member1, member2));

        // when
        groupService.createGroup(1L, req);

        // then – capture the balances list and verify count
        ArgumentCaptor<List<Balance>> captor = ArgumentCaptor.forClass(List.class);
        then(balanceRepository).should().saveAll(captor.capture());
        List<Balance> savedBalances = captor.getValue();
        assertThat(savedBalances).hasSize(6); // n*(n-1) = 3*2 = 6
    }
}
