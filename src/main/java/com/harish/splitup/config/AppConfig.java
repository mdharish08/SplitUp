package com.harish.splitup.config;

import com.harish.splitup.auth.JwtAuthenticationProvider;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.filters.JwtTokenCreationFilter;
import com.harish.splitup.filters.JwtValidationFilter;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.List;

@Configuration
@EnableWebSecurity
public class AppConfig {

    UserRepository repository;
    JwtService jwtService;

    AppConfig(UserRepository userRepository, JwtService jwtService){
        this.repository = userRepository;
        this.jwtService = jwtService;
    }

    @Bean
    public UserDetailsService userDetailsManager(){
        return (userName) -> repository.findByEmailId(userName).orElse(null);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider(){
        DaoAuthenticationProvider daoProvider = new DaoAuthenticationProvider(this.passwordEncoder());
        daoProvider.setUserDetailsService(userDetailsManager());
        return daoProvider;
    }

    @Bean
    public JwtAuthenticationProvider jwtAuthenticationProvider(){
        return new JwtAuthenticationProvider(this.userDetailsManager(), this.jwtService);
    }


    @Bean
    public AuthenticationManager authManager(){
        return new ProviderManager(List.of(daoAuthenticationProvider(),jwtAuthenticationProvider()));
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        JwtTokenCreationFilter jwtTokenCreationFilter = new JwtTokenCreationFilter(this.jwtService,authManager());
        JwtValidationFilter jwtValidationFilter = new JwtValidationFilter(this.jwtService,authManager());
        return http.authorizeHttpRequests(authorizationManagerRequestMatcherRegistry -> {
                            authorizationManagerRequestMatcherRegistry
                            .requestMatchers("/h2-console/**").permitAll()
                            .anyRequest().authenticated();
                    })
                    .sessionManagement(httpSecuritySessionManagementConfigurer -> httpSecuritySessionManagementConfigurer.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                    .csrf(AbstractHttpConfigurer::disable)
                    .headers( httpSecurityHeadersConfigurer ->  httpSecurityHeadersConfigurer.frameOptions(HeadersConfigurer.FrameOptionsConfig::disable))
                    .addFilterBefore(jwtTokenCreationFilter, UsernamePasswordAuthenticationFilter.class)
                    .addFilterAfter(jwtValidationFilter,JwtTokenCreationFilter.class)
                    .build();
    }

    @Bean
    public CommandLineRunner runner(){
        return (args -> {
            repository.save(SplitUser.builder().withFirstName("harish").withUserPassWord(passwordEncoder().encode("mdHarish")).withEmailId("mohamedharishupm@gmail.com").build());
        });
    }

}
