

variable "iot_topic"{
    description = "The MQTT topic that the IoT device messages will be publishing to"
    type        = string
    default     = "environment/telemetry"
}

variable "project_name"{
    description = "The base name used when creating streams etc"
    type        = string
    default     = "mkr_1010_template"
}

variable "thing_name"{
    description = "The name of the device (thing) to register in Core IoT"
    type        = string
    default     = "mkr_1010_env_thing"
}
