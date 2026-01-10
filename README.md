# Sistema de Loteria - QBox Framework

## Jack Lotus

Sistema de loteria moderno para servidores FiveM usando QBox framework.

## Características

- ✅ NPC interativo com ox_target
- ✅ Interface NUI moderna
- ✅ Sistema de sorteio automático
- ✅ Prêmios acumulativos
- ✅ Compatível com QBox framework
- ✅ Salva em banco de dados para acumular

## Instalação

1. Coloque o resource na pasta `resources`
2. Execute o arquivo `.sql` no seu banco de dados
3. Adicione no `server.cfg`:
   ```
   ensure qbx_core
   ensure ox_target
   ensure [nome_do_resource]
   ```
4. Reinicie o servidor

## Configuração

Edite o `config.lua` para ajustar:

- Posição do NPC
- Valores da loteria
- Tempo entre sorteios
- Configurações do blip

## Dependências

- qbx_core
- ox_target

## Suporte

Sistema testado e funcional com QBox framework.