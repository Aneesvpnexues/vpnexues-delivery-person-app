package com.vpnexues.partner;

import com.vpnexues.partner.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(AppProperties.class)
public class PartnerApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(PartnerApiApplication.class, args);
    }
}
