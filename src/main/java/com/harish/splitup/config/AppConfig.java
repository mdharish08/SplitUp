package com.harish.splitup.config;

import com.harish.splitup.auth.JwtAuthenticationProvider;
import com.harish.splitup.entities.Category;
import com.harish.splitup.filters.JwtTokenCreationFilter;
import com.harish.splitup.filters.JwtValidationFilter;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.JwtService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.List;
import java.util.stream.Stream;

@Configuration
@EnableWebSecurity
public class AppConfig {

    private final UserRepository repository;
    private final JwtService jwtService;

    public AppConfig(UserRepository userRepository, JwtService jwtService) {
        this.repository = userRepository;
        this.jwtService = jwtService;
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> repository.findByEmailId(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider(UserDetailsService uds, PasswordEncoder pe) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(pe);
        provider.setUserDetailsService(uds);
        return provider;
    }

    @Bean
    public JwtAuthenticationProvider jwtAuthenticationProvider(UserDetailsService uds) {
        return new JwtAuthenticationProvider(uds, jwtService);
    }

    @Bean
    public AuthenticationManager authManager(DaoAuthenticationProvider daoProvider,
                                             JwtAuthenticationProvider jwtProvider) {
        return new ProviderManager(List.of(daoProvider, jwtProvider));
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, AuthenticationManager authManager) throws Exception {
        JwtTokenCreationFilter tokenCreationFilter = new JwtTokenCreationFilter(jwtService, authManager);
        JwtValidationFilter validationFilter = new JwtValidationFilter(authManager);

        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/h2-console/**").permitAll()
                        .requestMatchers("/api/v1/signup", "/api/v1/categories").permitAll()
                        .anyRequest().authenticated())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .csrf(AbstractHttpConfigurer::disable)
                .headers(h -> h.frameOptions(HeadersConfigurer.FrameOptionsConfig::disable))
                .exceptionHandling(ex -> ex.authenticationEntryPoint(
                        (request, response, e) -> response.sendError(
                                jakarta.servlet.http.HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized")))
                .addFilterBefore(tokenCreationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterAfter(validationFilter, JwtTokenCreationFilter.class)
                .build();
    }

    @Bean
    public CommandLineRunner seedInitialUser(PasswordEncoder passwordEncoder) {
        return args -> {
            if (repository.findByEmailId("mohamedharishupm@gmail.com").isEmpty()) {
                repository.save(com.harish.splitup.entities.SplitUser.builder()
                        .withFirstName("harish")
                        .withUserPassWord(passwordEncoder.encode("mdHarish"))
                        .withEmailId("mohamedharishupm@gmail.com")
                        .build());
            }
        };
    }

    @Bean
    public CommandLineRunner seedCategories(CategoryRepository categoryRepository) {
        return args -> {
            if (categoryRepository.count() == 0) {
                Stream.of("Food & Drink", "Transportation", "Entertainment",
                                "Utilities", "Rent", "Shopping", "Other")
                        .map(name -> {
                            Category c = new Category();
                            c.setName(name);
                            return c;
                        })
                        .forEach(categoryRepository::save);
            }
        };
    }
}
